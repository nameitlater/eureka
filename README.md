eureka
======

Service discovery api.

Eureka is a service discovery api suitable for discovering in-process or out-of-process services. 
Services list their location via a uri as well as provide information about themselves using simple labels.
Clients use these labels to discover services they're interested in.  Service availability
can be monitored using watch. Eureka currently supports [etcd](https://github.com/coreos/etcd) as a backend.


*example*


```

  var discovery = new EtcdDiscovery(path: TEST_DIRECTORY + '/services');

  var uri = Uri.parse('tcp://127.0.0.1:6000');
  var labels = {
    'environment': 'prod'
  };

  schedule(() {
    return discovery.list(uri, labels);
  }).then((ListingEvent le) {
    expect(le.type, equals(ListingEventType.ADDED));
    expect(le.listing.uri, equals(uri));
    expect(le.listing.labels, equals(labels));
  }).whenComplete(() {
    discovery.close();
  });


```

_supported backends_
- [etcd](https://github.com/coreos/etcd)
