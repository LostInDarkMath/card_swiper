import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';

import 'full_screen_image.dart';

void main() => runApp(const MyApp());

const IMAGES = [
  NetworkImage('https://picsum.photos/250?image=9'),
  NetworkImage('https://picsum.photos/250?image=10'),
  NetworkImage('https://picsum.photos/250?image=11'),
];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light(),
      home: const MyHomePage(title: 'Flutter Swiper'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _swiperController = SwiperController();

  @override
  void dispose(){
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> onTapOnImage() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => FullScreenImage(
          image: Image(
            image:IMAGES[_swiperController.index],
            loadingBuilder: (context, child, loadingProgress) {
              if(loadingProgress == null){
                return child;
              }

              return const CircularProgressIndicator();
            },
          ),
          isNavigationEnabled: true,
          onSwipeRight: () async {
            print('BEFORE PREVIOUS RIGHT ${_swiperController.index}');
            await _swiperController.move((_swiperController.index - 1) % 3, animation: false); // animation false is important here!
            print('AFTER PREVIOUS RIGHT ${_swiperController.index}');
            return Image(
              image:IMAGES[_swiperController.index],
              loadingBuilder: (context, child, loadingProgress) {
                if(loadingProgress == null){
                  return child;
                }

                return const CircularProgressIndicator();
              },
            );
          },
          onSwipeLeft: () async {
            print('BEFORE PREVIOUS LEFT ${_swiperController.index}');
            await _swiperController.move((_swiperController.index + 1) % 3, animation: false);
            print('AFTER PREVIOUS LEFT ${_swiperController.index}');
            return Image(
              image:IMAGES[_swiperController.index],
              loadingBuilder: (context, child, loadingProgress) {
                if(loadingProgress == null){
                  return child;
                }

                return const CircularProgressIndicator();
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              print('before right ${_swiperController.index}');
              await _swiperController.move((_swiperController.index - 1) % 3);
              print('after right ${_swiperController.index}');
            },
            icon: const Icon(Icons.back_hand_outlined),
          ),
          IconButton(
            onPressed: () async {
              print('before left ${_swiperController.index}');
              await _swiperController.move((_swiperController.index + 1) % 3);
              print('after left ${_swiperController.index}');
            },
            icon: const Icon(Icons.forward),
          ),
        ],
      ),
      body: InkWell(
        onTap: onTapOnImage,
        child: SafeArea(
          child: Swiper(
            key: const ValueKey(3), // https://github.com/best-flutter/flutter_swiper/issues/64#issuecomment-636893600
            itemCount: 3,
            pagination: const SwiperPagination(),
            controller: _swiperController,
            onIndexChanged: (index) {
              print('on index changed: $index');
            },
            itemBuilder: (context, index){
              return Image(
                image:IMAGES[index],
                loadingBuilder: (context, child, loadingProgress) {
                  if(loadingProgress == null){
                    return child;
                  }

                  return const CircularProgressIndicator();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
