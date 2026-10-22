function fn(creds) {
  var Base64 = Java.type('java.util.Base64');
  var JString = Java.type('java.lang.String');
  var raw = new JString(creds.username + ':' + creds.password);
  return 'Basic ' + Base64.getEncoder().encodeToString(raw.getBytes('UTF-8'));
}
