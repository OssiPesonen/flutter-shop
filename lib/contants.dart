const String apiKey = 'AIzaSyAScG11vWvYQXBZU0fk3DgOUaQPTM4W8wE';

const String apiUrl =
    'https://flutter-demo-39ad3-default-rtdb.europe-west1.firebasedatabase.app';

Uri getApiUrl({String append = ''}) => Uri.parse(apiUrl + append);

Uri signInUrl() => Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');

Uri signUpUrl() => Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
