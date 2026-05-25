import 'package:flutter/material.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/utils/coloors.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.contactSource, required this.onTap,
  });

  final UserModel contactSource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 20,right: 10,),
      leading: CircleAvatar(
        backgroundColor: context.theme.greyColor!.withOpacity(0.3),
        radius: 20,
        backgroundImage: contactSource.profileImageUrl.isNotEmpty?NetworkImage(contactSource.profileImageUrl):null,
        child: contactSource.profileImageUrl.isEmpty? Icon(Icons.person,size: 30,color: Colors.white,)
        :null,
      ),
      title:Text(contactSource.username,style: TextStyle(
        fontSize: 16,fontWeight: FontWeight.w500
      ),),
      subtitle: contactSource.profileImageUrl.isEmpty? null : Text("Hey there I'm using WhatsApp",style: TextStyle(
        color: context.theme.greyColor,fontWeight: FontWeight.w600,
    
      ),),
      trailing:contactSource.profileImageUrl.isEmpty ? TextButton(onPressed: onTap,
                    style: TextButton.styleFrom(foregroundColor: Coloors.greenDark), child: const Text('INVITE')):null,
    );
  }
}