// Copyright (c) 2014, the Name It Later Eureka project authors.
// Please see the AUTHORS file for details. All rights reserved. Use of this 
// source code is governed by the BSD 3 Clause license, a copy of which can be
// found in the LICENSE file.

library eureka.src.discovery;

import 'dart:async';

class ListingEventType {
  
  final String _toString;
  
  const ListingEventType._(this._toString);
  
  static const ADDED = const ListingEventType._('ADDED');
  static const REMOVED = const ListingEventType._('REMOVED');
  static const MODIFIED = const ListingEventType._('MODIFIED');
  
  String toString(){
    return _toString;
  }
  
}

class Listing {
  final Uri uri;
  final Map<String, String> labels;
  final DateTime expiration;
  Listing(this.uri, this.labels, {DateTime expiration}) : this.expiration = expiration;
  
  String toString(){
    return '{"uri": ${uri}, "labels": $labels} "expiration": $expiration';
  }
}

class ListingEvent {
  ListingEventType type;
  Listing listing;
  
  ListingEvent(this.type, this.listing);
  
  toString(){
    return '{"type": $type, "listing": $listing}';
  }
}

//mirror etcd with DiscoveryEvent
abstract class Discovery {
  Future delist(Uri uri);
  Future<ListingEvent> list(Uri uri, Map<String, String> labels, {Duration ttl});
  Future<List<Listing>> discover([Map<String, String> labels]);
  Stream<ListingEvent> watch(Map<String, String> labels);
  close();
}


