import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:nendo_image_downloader/nendoroid_model.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageDownloadManager {
  final Duration delay = const Duration(milliseconds: 100);
  final String oldGoodSmileUrl = 'https://www.goodsmile.info/en/product/';
  final String newGoodSmileUrl = 'https://www.goodsmile.com/en/product';

  Directory? downloadDirPath;

  Future<void> startDownload({
    required String folderPath,
    required Function(double progress) progress,
  }) async {
    downloadDirPath ??= await getDownloadsDirectory();

    final List<NendoroidModel> nendoDataList = parseJson(jsonFolder: folderPath);

    if (nendoDataList.isEmpty) {
      return Future.error('데이터가 없습니다.');
    }

    try {
      for (int i = 0; i < nendoDataList.length; i++) {
        final model = nendoDataList[i];
        final List<String> imageUrls = await getThumbnailImageUrls(model);
        final folderPath = path.join(downloadDirPath!.path, 'nendoImage/${model.num}');

        // 썸네일 다운로드
        await downloadImage(
          url: model.image,
          folderPath: folderPath,
          fileName: '${model.num}_thumbnail.jpg',
        );

        // 샘플이미지 다운로드
        for (int j = 0; j < imageUrls.length; j++) {
          final fileName = '${model.num}_$j.jpg';

          try {
            await downloadImage(
              url: imageUrls[j],
              folderPath: folderPath,
              fileName: fileName,
            );
          } catch (error, _) {
            continue;
          }

          await Future.delayed(delay);
        }

        progress((i + 1) / nendoDataList.length);
      }
    } catch (error, stackTrace) {
      return Future.error(error, stackTrace);
    }
  }

  // 넨도로이드 폴더에 접근하여 json파일을 순회하면서 필요한 데이터를 뽑아 데이터클래스로 변환해준다.
  List<NendoroidModel> parseJson({required String jsonFolder}) {
    final Directory directory = Directory(jsonFolder);
    final List<FileSystemEntity> files = directory.listSync();
    final List<NendoroidModel> nendoroidList = [];

    for (final FileSystemEntity file in files) {
      if (file is File && path.extension(file.path) == '.json') {
        final String content = file.readAsStringSync();
        final Map<String, dynamic> json = jsonDecode(content);
        final NendoroidModel nendoroid = NendoroidModel.fromJson(json);
        nendoroidList.add(nendoroid);
        print('@@@ parse success : $nendoroid');
      }
    }

    return nendoroidList;
  }

  Future<List<String>> getThumbnailImageUrls(NendoroidModel model) async {
    final baseUrl = model.image.contains('goodsmile.info') ? oldGoodSmileUrl : newGoodSmileUrl;
    final List<String> imageUrls = [];
    final response = await http.get(Uri.parse('$baseUrl/${model.gscProductNum}'));

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);

      final photosClass = document.getElementsByClassName('itemPhotos').firstOrNull;
      if (photosClass != null) {
        final liElements = photosClass.querySelector('ul');
        if (liElements == null) {
          return [];
        }
        for (final li in liElements.children) {
          final imageClass = li.getElementsByClassName('itemImg').firstOrNull;
          if (imageClass == null) {
            continue;
          }
          final imgUrl = imageClass.attributes['src'];
          imageUrls.add('http:$imgUrl');
          print('@@@ image url : $imgUrl');
        }
      }
      return imageUrls;
    } else {
      // 404 에러시 페이지가 없으므로 이미지가 없다고 판단
      if (response.statusCode == 404) {
        return [];
      }
      // 403 에러시 일정 시간을 두고 재시도
      if (response.statusCode == 403) {
        await Future.delayed(const Duration(seconds: 5));
        return getThumbnailImageUrls(model);
      }
      return Future.error('기타 네트워크 오류 : ${response.statusCode}');
    }
  }

  Future<void> downloadImage({required String url, required String folderPath, required String fileName}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        // 폴더가 없다면 생성
        final Directory folder = Directory(folderPath);
        if (!folder.existsSync()) {
          folder.createSync(recursive: true);
        }
        final File file = File(path.join(folderPath, fileName));
        await file.writeAsBytes(bytes);
        print('Downloaded : $fileName');
      } else {
        print('@@@ Network Error : ${response.statusCode}');
        return Future.error('Network Error : ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      print('@@@ Download Error : $error');
      return Future.error(error, stackTrace);
    }
  }
}
