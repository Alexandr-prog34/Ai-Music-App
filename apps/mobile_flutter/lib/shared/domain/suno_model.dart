enum SunoModel{
  v4('V4'),
  v45('V4_5'),
  v45plus('V4_5PLUS'),
  v45all('V4_5ALL'),
  v5('V5');

  final String value;

  const SunoModel(this.value);

  //JSON → enum
  static SunoModel fromJson(String? value) {
    if (value == null) {
      return SunoModel.v45all; //дефолт
    }

    for (final model in SunoModel.values) {
      if (model.value == value) {
        return model;
      }
    }
    return SunoModel.v45all;
  }

  //enum → JSON
  String toJson(){
    return value;
  }
}
  
