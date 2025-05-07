import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:runqpp/shared/colors.dart';

class EditHotelPage extends StatefulWidget {
  final String hotelId;
  final Map<String, dynamic> hotel;

  const EditHotelPage({
    Key? key,
    required this.hotelId,
    required this.hotel,
  }) : super(key: key);

  @override
  _EditHotelPageState createState() => _EditHotelPageState();
}

class _EditHotelPageState extends State<EditHotelPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nomController;
  late TextEditingController localisationController;
  late TextEditingController prixController;
  late TextEditingController chambresController;
  late TextEditingController descriptionController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.hotel;
    nomController = TextEditingController(text: data['nom']);
    localisationController = TextEditingController(text: data['localisation']);
    prixController = TextEditingController(text: data['prix'].toString());
    chambresController =
        TextEditingController(text: data['chambres'].toString());
    descriptionController = TextEditingController(text: data['description']);
  }

  Future<void> _updateHotel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    await FirebaseFirestore.instance
        .collection('hotels')
        .doc(widget.hotelId)
        .update({
      'nom': nomController.text.trim(),
      'localisation': localisationController.text.trim(),
      'prix': double.parse(prixController.text),
      'chambres': int.parse(chambresController.text),
      'description': descriptionController.text.trim(),
      // TODO: gérer image si besoin
    });
    setState(() => isLoading = false);

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Succès',
      text: 'Hôtel mis à jour',
      onConfirmBtnTap: () {
        Navigator.of(context).pop(); // Ferme l'alerte
        Navigator.of(context).pop(); // Retour à la page précédente
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Modifier Hôtel",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField('Nom', nomController),
                    _buildField('Localisation', localisationController),
                    _buildField('Prix (TND)', prixController,
                        type: TextInputType.number),
                    _buildField('Nombre de chambres', chambresController,
                        type: TextInputType.number),
                    _buildField('Description', descriptionController, lines: 4),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateHotel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text(
                          'Mettre à jour',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
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
          TextFormField(
            controller: controller,
            keyboardType: type,
            maxLines: lines,
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            decoration: InputDecoration(
              hintText: 'Entrez $label',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
