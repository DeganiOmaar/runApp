// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:runqpp/profilepages/edit_profile.dart';
import 'package:runqpp/profilepages/profilecard.dart';
import 'package:runqpp/registerScreens/login.dart';
import 'package:runqpp/shared/colors.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map userData = {};
  bool isLoading = true;

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      userData = snapshot.data()!;
    } catch (e) {
      print(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: LoadingAnimationWidget.discreteCircle(
              size: 32,
              color: const Color.fromARGB(255, 16, 16, 16),
              secondRingColor: Colors.indigo,
              thirdRingColor: Colors.pink.shade400,
            ),
          ),
        )
        : Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Positioned(
                      child: Container(height: 300, color: Colors.white),
                    ),
                    Positioned(child: Container(height: 240, color: mainColor)),
                    Positioned(
                      top: 180,
                      right: MediaQuery.of(context).size.width / 2 - 60,
                      child: Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: SvgPicture.asset(
                            'assets/images/avatar.svg',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${userData['nom']} ${userData['prenom']}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Gap(20),
                        Row(
                          children: [
                            const Text(
                              "Telephone",
                              style: TextStyle(
                                fontSize: 17,
                                // fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "+216 ${userData['phone']}",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Gap(20),
                        Row(
                          children: [
                            const Text(
                              "Email",
                              style: TextStyle(
                                fontSize: 17,
                                // fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            Spacer(),
                            Text(
                              userData['email'],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Gap(20),
                        Divider(thickness: 1, color: Colors.grey[200]),
                        Gap(10),
                        ProfileSettingCard(
                          text: "Modifier votre profil",
                          icon: LineAwesomeIcons.user_edit_solid,
                          onPressed: () async {
                            Get.to(() => EditProfilePage());
                          },
                        ),
                        Gap(20),
                        ProfileSettingCard(
                              text: "Obtenir l'aide",
                              icon: CupertinoIcons.question,
                              onPressed: () {},
                            ),
                         
                        Gap(20),
                        ProfileSettingCard(
                          text: "A propos de nous",
                          icon: CupertinoIcons.info,
                          onPressed: () {},
                        ),
                        Gap(20),
                        ProfileSettingCard(
                          text: "Supprimer le compte",
                          icon: CupertinoIcons.delete,
                          onPressed: () {},
                        ),
                        Gap(20),
                        ListTile(
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.blue.withOpacity(0.1),
                            ),
                            child: Icon(
                              LineAwesomeIcons.sign_in_alt_solid,
                              color: Colors.red[800],
                            ),
                          ),
                          title: Text(
                            "Déconnexion",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.red[800],
                            ),
                          ),
                          trailing: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            child: Icon(
                              LineAwesomeIcons.angle_right_solid,
                              color: Colors.black87,

                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}