enum SunoModel{
  V4('V4'),
  V4_5('V4_5'),
  V4_5PLUS('V4_5PLUS'),
  V4_5ALL('V4_5ALL'),
  V5('V5');

  final String value;

  const SunoModel(this.value);

  //JSON → enum
  static SunoModel fromJson(String? value) {
    if (value == null) {
      return SunoModel.V4_5ALL; //дефолт
    }

    for (final model in SunoModel.values) {
      if (model.value == value) {
        return model;
      }
    }
    return SunoModel.V4_5ALL;
  }

  //enum → JSON
  String toJson(){
    return value;
  }
}
  
