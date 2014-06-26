// Copyright (c) 2014, the Name It Later Eureka project authors.
// Please see the AUTHORS file for details. All rights reserved. Use of this
// source code is governed by the BSD 3 Clause license, a copy of which can be
// found in the LICENSE file.

library eureka.src.etcd;

import 'dart:async';
import 'dart:convert';
import 'discovery.dart';
import 'package:logging/logging.dart';
import 'package:ezetcd/ezetcd.dart';

final Logger _LOGGER = new Logger('eureka.etcd');

/**
 * An etcd implementation of [Discovery].
 */
class EtcdDiscovery implements Discovery {

  final EtcdClient _client;
  final String _path;

  StreamController<ListingEvent> _events;
  StreamSubscription _watchSub;

  EtcdDiscovery({host: '127.0.0.1', port: 4001, path: '/services'})
      : this._path = path,
        this._client = new EtcdClient(host: host, port: port) {
    _events = new StreamController.broadcast(onListen: _observed, onCancel: _unobserved);
  }

  @override
  close() {
    _events.close();
    _client.close();

  }

  @override
  Future<ListingEvent> list(Uri location, Map<String, String> labels, {Duration ttl}) {
    var completer = new Completer();
    _client.setNode(_locationToKey(_path, location), value: JSON.encode({
      'location': location.toString(),
      'labels': labels
    })).then((NodeEvent ne) {
      completer.complete(_nodeEventToListingEvent(ne));
    }).catchError((error, stacktrace) {
      completer.completeError(error, stacktrace);
    });
    return completer.future;
  }

  @override
  Future<List<Listing>> discover([Map<String, String> labels = const {}]) {
    var completer = new Completer();
    _client.getNode(_path).then((node) {
      completer.complete(node.nodes.map((Node node) {
        return _nodeToListing(node);
      }));
    }).catchError((e, ss) {
      completer.completeError(e, ss);
    });
    return completer.future;
  }

  @override
  Future<ListingEvent> delist(Uri location) {
    var completer = new Completer();
    _client.deleteNode(_locationToKey(_path, location)).then((NodeEvent ne) {
      var json = JSON.decode(ne.oldValue.value);
      completer.complete(_nodeEventToListingEvent(ne));
    }).catchError((e, ss) {
      completer.completeError(e, ss);
    });
    return completer.future;
  }

  @override
  Stream<ListingEvent> watch(Map<String, String> labels) {
    return _events.stream.where((ListingEvent e) {
      var matches = true;
      for (var key in labels.keys) {
        if (!e.listing.labels.containsKey(key) || e.listing.labels[key] != labels[key]) {
          matches = false;
          break;
        }
      }
      return matches;
    });
  }

  _observed() {
    _watchSub = _client.watch(_path, recursive: true).listen((e) {
      _events.add(_nodeEventToListingEvent(e));
    }, onError: ((e, ss) {
      _events.addError(e, ss);
    }));
  }

  _unobserved() {
    _watchSub.cancel();
  }

  static ListingEvent _nodeEventToListingEvent(NodeEvent e) {
    switch (e.type) {
      case NodeEventType.CREATED:
        var json = JSON.decode(e.newValue.value);
        return new ListingEvent(ListingEventType.ADDED, new Listing(Uri.parse(json['location']), json['labels'], expiration: e.newValue.expiration));
      case NodeEventType.MODIFIED:
        var json = JSON.decode(e.newValue.value);
        return new ListingEvent(ListingEventType.MODIFIED, new Listing(Uri.parse(json['location']), json['labels'], expiration: e.newValue.expiration));
      default:
        var json = JSON.decode(e.oldValue.value);
        return new ListingEvent(ListingEventType.REMOVED, new Listing(Uri.parse(json['location']), json['labels'], expiration: e.oldValue.expiration));
    }
  }

  _nodeToListing(Node n) {
    var json = JSON.decode(n.value);
    return new Listing(Uri.parse(json['location']), json['labels'], expiration: n.expiration);
  }

  static String _locationToKey(String path, Uri location) {
    return '$path/${location.scheme}_${location.authority}_${location.path}';
  }

}
