String? validatePassword(text) {
  if (text.length < 4) {
    return 'Too short';
  }
  if (text.length > 20) {
    return 'Too Long';
  }
  //Minimum eight characters, at least one uppercase letter, one lowercase letter, one number and one special character:
  // RegExp regex = new RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
  // if (!regex.hasMatch(text)) {
  //   return 'Password needs to be minimum 8 characters with atleast one uppercase, lowercase, number, and special character';
  // }
  // return null if the text is valid
  return null;
}

String? validatePhoneNumber(text) {
  if (text.length != 12) return 'Phone Number should be 10 digits';
  return null;
}

String? validatePhoneConfirmation(text) {
  if (text.length != 4) return 'Confirmation should be 4 digits';
  return null;
}

String? validateText(text) {
  return null;
}
