import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/widgets/custom_icon_button.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  List<Widget> imageList =[];
  int curretPage=0;
  int? lastPage;

  handleScrollEvent(ScrollNotification scroll){
    if(scroll.metrics.pixels / scroll.metrics.maxScrollExtent <= .33) return;
    if(curretPage==lastPage) return;
    fetchAllImages();
  }

  fetchAllImages() async {
    lastPage=curretPage;
  final permission = await PhotoManager.requestPermissionExtend();
  
  if (permission.isAuth || permission.hasAccess) {  // ← agrega hasAccess
    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    
    if (albums.isEmpty) return;  // ← agrega esta verificación
    
    List<AssetEntity> photos = await albums[0].getAssetListPaged(
      page: curretPage,
      size: 24,
    );
    
    List<Widget> temp = [];

    for (var asset in photos) {
      temp.add(FutureBuilder(
        future: asset.thumbnailDataWithSize(ThumbnailSize(200, 200),),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ClipRRect(
              child: InkWell(
                onTap: ()=>Navigator.pop(context,snapshot.data),
                borderRadius: BorderRadius.circular(5),
                splashFactory: NoSplash.splashFactory,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.theme.greyColor!.withOpacity(0.4),
                      width: 1,
                    ),
                    image: DecorationImage(
                      image: MemoryImage(snapshot.data as Uint8List),
                      fit: BoxFit.cover,  // ← agrega fit
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ));
    }
    setState(() {
      imageList.addAll(temp);
      curretPage ++;
    });
  } else {
    PhotoManager.openSetting();  // ← solo abre settings si se denegó
  }
}

  @override
  void initState() {
    fetchAllImages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        //elevation: 0,
        leading: CustomIconButton(onTap: ()=> Navigator.pop(context),icon: Icons.arrow_back,),
        title: 
        Text(
          'WhatsApp',
          style: TextStyle(color: context.theme.authAppBarTextColor),
        ),
        actions: [
          CustomIconButton(
            onTap: (){},
            icon: Icons.more_vert,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(5),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scroll){
            handleScrollEvent(scroll);
            return true;
          },
          child: GridView.builder(
            itemCount: imageList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),itemBuilder:(_,index){
            return imageList[index];
          }),
        ),
      ),
    );
  }
}