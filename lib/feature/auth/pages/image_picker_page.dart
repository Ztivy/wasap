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

  fetchAllImages()async{
    final permission = await PhotoManager.requestPermissionExtend();
    if(!permission.isAuth) return PhotoManager.openSetting();

    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    List<AssetEntity> photos = await albums[0].getAssetListPaged(
      page: 0,
      size: 24
    );
    
    List<Widget>temp=[];

    for(var asset in photos){
        temp.add(FutureBuilder(future: asset.thumbnailData,builder: (context,Snapshot){
          if(Snapshot.connectionState == ConnectionState.done){
            return Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: MemoryImage(Snapshot.data as Uint8List),),
            ),
          );
          }
          return SizedBox();
        },),
      );
    }
    setState(() {
      imageList.addAll(temp);
    });
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
        elevation: 0,
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
      body: GridView.builder(
        itemCount: imageList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),itemBuilder:(_,index){
        return imageList[index];
      }),
    );
  }
}