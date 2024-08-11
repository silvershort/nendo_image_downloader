class NendoroidModel {
  final int gscProductNum;
  final String image;
  final String num;

  NendoroidModel({
    required this.gscProductNum,
    required this.image,
    required this.num,
  });

  factory NendoroidModel.fromJson(Map<String, dynamic> json) {
    return NendoroidModel(
      gscProductNum: json['gsc_productNum'],
      image: json['image'],
      num: json['num'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gsc_productNum': gscProductNum,
      'image': image,
      'num': num,
    };
  }

  @override
  String toString() {
    return 'NendoroidModel{gscProductNum: $gscProductNum, image: $image, num: $num}';
  }
}