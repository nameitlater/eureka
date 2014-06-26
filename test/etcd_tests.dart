// Copyright (c) 2014, the Name It Later Eureka project authors.
// Please see the AUTHORS file for details. All rights reserved. Use of this 
// source code is governed by the BSD 3 Clause license, a copy of which can be
// found in the LICENSE file.

import 'dart:async';
import 'package:ezetcd/ezetcd.dart';
import 'package:eureka/eureka.dart';
import 'package:eureka/etcd.dart';
import 'package:scheduled_test/scheduled_test.dart';

const String TEST_DIRECTORY = '/eureka_tests';

main() {
  test('should setup', _shouldSetup);
  test('should list service', _shouldListService);
  test('should update listing', _shouldUpdateListing);
  test('should delete listing', _shouldDeleteListing);
  test('should watch listings', _shouldWatchListings);
  test('should teardown', _shouldTeardown);
}

_shouldSetup() {
  var client = new EtcdClient();

  schedule(() {
    return client.deleteNode(TEST_DIRECTORY, recursive: true);
  });

  schedule(() {
    return client.setNode(TEST_DIRECTORY, directory: true);
  });
}

_shouldTeardown() {
  var client = new EtcdClient();

  schedule(() {
    return client.deleteNode(TEST_DIRECTORY, recursive: true);
  });

}

_shouldListService() {

  var eureka = new EtcdEureka(path: TEST_DIRECTORY + '/services');

  var location = Uri.parse('tcp://127.0.0.1:6000');
  var labels = {
    'environment': 'prod'
  };

  schedule(() {
    return eureka.list(location, labels);
  }).then((ListingEvent le) {
    expect(le.type, equals(ListingEventType.ADDED));
    expect(le.listing.location, equals(location));
    expect(le.listing.labels, equals(labels));
  }).whenComplete(() {
    eureka.close();
  });
}

_shouldUpdateListing() {

  var eureka = new EtcdEureka(path: TEST_DIRECTORY + '/services');

  var location = Uri.parse('tcp://127.0.0.1:6000');
  var labels = {
    'environment': 'prod'
  };

  schedule(() {
    return eureka.list(location, labels);
  });



  schedule(() {
    labels['environment'] = 'test';
    return eureka.list(location, labels);
  }).then((ListingEvent le) {
    expect(le.type, equals(ListingEventType.MODIFIED));
    expect(le.listing.location, equals(location));
    expect(le.listing.labels, equals(labels));
  }).whenComplete(() {
    eureka.close();
  });

}

_shouldDeleteListing() {

  var eureka = new EtcdEureka(path: TEST_DIRECTORY + '/services');

  var location = Uri.parse('tcp://127.0.0.1:6000');
  var labels = {
    'environment': 'prod'
  };

  schedule(() {
    return eureka.list(location, labels);
  });

  schedule(() {
    return eureka.delist(location);
  }).then((ListingEvent le) {
    expect(le.type, equals(ListingEventType.REMOVED));
    expect(le.listing.location, equals(location));
    expect(le.listing.labels, equals(labels));
  }).whenComplete(() {
    eureka.close();
  });

}

_shouldWatchListings() {
  var eureka = new EtcdEureka(path: TEST_DIRECTORY + '/services');

  var events = [];

  var labels = {
    'environment': 'prod'
  };

  var eventsReady = new Completer();

  schedule(() {
    var sub;
    sub = eureka.watch(labels).listen((e) {
      events.add(e);
      if (events.length == 1) {
        sub.cancel();
        eventsReady.complete(events);
      }
    }, onError: (e, ss) {
      eventsReady.completeError(e, ss);
    });
    return new Future.delayed(new Duration(seconds: 1));
  });

  var location = Uri.parse('tcp://127.0.0.1:6000');
  
  schedule(() {
    eureka.list(location, labels);
  });

  schedule(() {
    var completer = new Completer();
    eventsReady.future.then((e) {
      expect(events.length, equals(1));
      expect(events[0].type, equals(ListingEventType.ADDED));
      expect(events[0].listing.location, equals(location));
      completer.complete();
    }).catchError((e, ss) {
      completer.completeError(e, ss);
    });
    return completer.future;
  }).whenComplete(() {
    eureka.close();
  });


}
