import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nendo_image_downloader/default_dialog.dart';
import 'package:nendo_image_downloader/image_download_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ImageDownloadManager downloadManager = ImageDownloadManager();
  double progress = 0;
  bool downloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              downloading ? '다운로드 중 입니다.' : '대기중 입니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  downloading = true;
                });
                try {
                  const int start = 0;
                  const int end = 26;

                  for (int i = start; i < end; i++) {
                    final NumberFormat formatter = NumberFormat('00');
                    final number = formatter.format(i);

                    await downloadManager.startDownload(
                      folderPath: 'C:\\Users\\KHS\\Documents\\NendoroidDB\\Nendoroid\\${number}00-${number}99',
                      progress: (progress) {
                        setState(() {
                          this.progress = (i + 1) / 25;
                        });
                      },
                    );
                  }

                  if (context.mounted) {
                    showAlertDialog(
                      context,
                      content: '다운로드 완료',
                    );
                  }
                } catch (error, _) {
                  if (context.mounted) {
                    showAlertDialog(
                      context,
                      content: '다운로드 실패 : $error',
                    );
                  }
                } finally {
                  setState(() {
                    downloading = false;
                    progress = 0;
                  });
                }
              },
              child: const Text('다운로드 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
