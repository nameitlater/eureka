// Copyright (c) 2014, the Name It Later Eureka project authors.
// Please see the AUTHORS file for details. All rights reserved. Use of this 
// source code is governed by the BSD 3 Clause license, a copy of which can be
// found in the LICENSE file.
/**
 * Discovery api
 */
library eureka.src.discovery;

import 'dart:async';

/**
 * The type of the [ListingEvent].
 * 
 * The type of the listing event.  Listing's can be ADDED, MODIFIED, and REMOVED.
 */
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

/**
 *  A listing for a service.
 *  
 *  A listing for a service.  The [Listing] specifies a [Uri] defining how to connect to
 *  the service as well a [Map] of labels describing the service that are matched to
 *  discover desired services.
 * 
 */
class Listing {
  
  /**
   *The uri used to connect to the service.
   */
  final Uri uri;
  
  /**
   * Labels describing the service.
   */
  final Map<String, String> labels;
  
  /**
   * The expiration time of the listing
   */
  final DateTime expiration;
  Listing(this.uri, this.labels, {DateTime expiration}) : this.expiration = expiration;
  
  String toString(){
    return '{"uri": ${uri}, "labels": $labels} "expiration": $expiration';
  }
}

/**
 * Event emitted by watch in response to changes in [Listing]'s. 
 */
class ListingEvent {
  
  /**
   * The type of the event.
   */
  ListingEventType type;
  
  /**
   * The [Listing] that changed.
   * 
   *  * new value of the [Listing] if the event is [ListingEventType.ADDED] or [ListingEventType.MODIFIED]
   *  * previous value of the [Listing] if the event is [ListingEventType.REMOVED]
   */
  Listing listing;
  
  ListingEvent(this.type, this.listing);
  
  toString(){
    return '{"type": $type, "listing": $listing}';
  }
}

/**
 * A Discovery service.
 */
abstract class Discovery {
  
  /**
   * Removes the [Listing] for [uri]
   * 
   * Returns a [Future] which completes with the [ListingEvent] that results from
   * delisting the service represented by [uri].
   */
  Future<ListingEvent> delist(Uri uri);
  
  /**
   * Lists the service represented by [uri].
   * 
   * Returns a [Future] which completes with the [ListingEvent] that results from
   * listing the service represented by [uri] for the [ttl].  
   * 
   *  * The [labels] given will be matched against in [discover] and [watch].
   *  
   *  * The [Listing] will removed when the [ttl] expires.
   * 
   *  * The [Listing] is be extended by calling [list] again. 
   */
  Future<ListingEvent> list(Uri uri, Map<String, String> labels, {Duration ttl});
  
  /**
   * Discover services that match [labels].
   * 
   * Returns a [Future] which completes with the [Listing]'s that match the [labels].
   */
  Future<List<Listing>> discover([Map<String, String> labels]);
  
  /**
   * Watch for services matching [labels].
   * 
   * Returns a [Stream] of [ListingEvent]'s for [Listing]'s that match [labels].
   */
  Stream<ListingEvent> watch(Map<String, String> labels);
  
  /**
   * Close the service and release all resources.
   */
  close();
}


