import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/quickalert.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../shared/colors.dart';

class AddHotelPage extends StatefulWidget {
  const AddHotelPage({super.key});

  @override
  State<AddHotelPage> createState() => _AddHotelPageState();
}

class _AddHotelPageState extends State<AddHotelPage> {
  final nomController = TextEditingController();
  final descriptionController = TextEditingController();
  final prixController = TextEditingController();
  final chambreController = TextEditingController();
  final localisationController = TextEditingController();

  File? imageFile;
  bool isUploading = false;

  Future<void> pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        imageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> ajouterHotel() async {
    if (nomController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        prixController.text.isEmpty ||
        chambreController.text.isEmpty ||
        localisationController.text.isEmpty ||
        imageFile == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Veuillez remplir tous les champs',
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('hotels/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await storageRef.putFile(imageFile!);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Add hotel document with imageUrl
      await FirebaseFirestore.instance.collection('hotels').add({
        'nom': nomController.text.trim(),
        'description': descriptionController.text.trim(),
        'prix': double.parse(prixController.text),
        'chambres': int.parse(chambreController.text),
        'localisation': localisationController.text.trim(),
        'imageUrl': imageUrl,
        'created_at': Timestamp.now(),
      });

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'Hôtel ajouté avec succès !',
      );

      // Reset fields
      nomController.clear();
      descriptionController.clear();
      prixController.clear();
      chambreController.clear();
      localisationController.clear();
      setState(() {
        imageFile = null;
      });
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Erreur lors de l\'ajout.',
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Ajouter un Hôtel",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: isUploading
          ? Center(
              child: LoadingAnimationWidget.discreteCircle(
                size: 32,
                color: Colors.black,
                secondRingColor: Colors.green,
                thirdRingColor: Colors.blue,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: imageFile == null
                            ? Center(
                                child: Icon(
                                  Icons.cloud_upload,
                                  size: 40,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  imageFile!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField("Nom de l'hôtel", nomController),
                  _buildField("Prix (TND)", prixController,
                      type: TextInputType.number),
                  _buildField(
                      "Nombre de chambres disponibles", chambreController,
                      type: TextInputType.number),
                  _buildField("Localisation", localisationController),
                  _buildField("Description", descriptionController, lines: 4),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: ajouterHotel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text("Ajouter l'hôtel",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {int lines = 1, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: lines,
            keyboardType: type,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Entrez $label",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: mainColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
