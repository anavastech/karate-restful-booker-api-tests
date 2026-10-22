function fn() {
  var UUID = Java.type('java.util.UUID');
  var LocalDate = Java.type('java.time.LocalDate');

  var suffix = function () {
    return ('' + UUID.randomUUID()).substring(0, 8);
  };

  // ISO date (yyyy-MM-dd) relative to today, so data never goes stale
  var date = function (daysFromToday) {
    return '' + LocalDate.now().plusDays(daysFromToday);
  };

  var uniqueName = function (prefix) {
    return prefix + '-' + suffix();
  };

  // Valid booking with unique names; overrides replace top-level fields, removals drop them
  var booking = function (overrides, removals) {
    var payload = karate.read('classpath:common/data/booking.json');
    payload.firstname = uniqueName('Karate');
    payload.lastname = uniqueName('Tester');
    payload.bookingdates = { checkin: date(30), checkout: date(35) };
    payload = karate.merge(payload, overrides || {});
    (removals || []).forEach(function (key) { delete payload[key]; });
    return payload;
  };

  return { suffix: suffix, date: date, uniqueName: uniqueName, booking: booking };
}
