enum VocalGender {
  m('m'),
  f('f');

  final String value;

  const VocalGender(this.value);


  static VocalGender? fromJson(String? value) {
    if (value == null) {
      return null;
    }

    for (final gender in VocalGender.values) {
      if (gender.value == value) {
        return gender;
      }
    }

    return null;
  }

  String toJson() {
    return value;
  }
}