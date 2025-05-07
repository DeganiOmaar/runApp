import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../shared/colors.dart';

class HotelDescriptionPage extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelDescriptionPage({Key? key, required this.hotel}) : super(key: key);

  @override
  State<HotelDescriptionPage> createState() => _HotelDescriptionPageState();
}

class _HotelDescriptionPageState extends State<HotelDescriptionPage> {
  int quantity = 1;

  Future<void> _reserver() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Erreur', 'Vous devez être connecté pour réserver.');
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};

    final double prixParNuit = widget.hotel['prix']?.toDouble() ?? 0.0;
    final double prixTotal = prixParNuit * quantity;

    await FirebaseFirestore.instance.collection('reservations').add({
      'userId': user.uid,
      'nomUtilisateur': userData['nom'] ?? '',
      'prenomUtilisateur': userData['prenom'] ?? '',
      'telephoneUtilisateur': userData['phone'] ?? '',
      'hotelNom': widget.hotel['nom'] ?? '',
      'nbrJours': quantity,
      'prixParNuit': prixParNuit,
      'prixTotal': prixTotal,
      'dateReservation': Timestamp.now(),
    });

    if (await _requestStoragePermission()) {
      await _generateAndSavePDF(userData);
    }

    Get.snackbar('Succès', 'Votre réservation a été enregistrée.');
    Navigator.pop(context);
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    Get.snackbar('Permission refusée', 'Impossible d’enregistrer le PDF.');
    return false;
  }

  Future<void> _generateAndSavePDF(Map<String, dynamic> userData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey, width: 2),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "Confirmation de Réservation",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey700),

                pw.Text(" Informations personnelles",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Bullet(text: "Nom : ${userData['nom'] ?? ''}"),
                pw.Bullet(text: "Prénom : ${userData['prenom'] ?? ''}"),
                pw.Bullet(text: "Téléphone : ${userData['phone'] ?? ''}"),

                pw.SizedBox(height: 20),

                // pw.Text("🏨 Informations sur l'hôtel",
                //     style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                // pw.SizedBox(height: 10),
                // pw.Bullet(text: "Nom de l'hôtel : ${widget.hotel['nom'] ?? ''}"),
                // pw.Bullet(text: "Localisation : ${widget.hotel['localisation'] ?? ''}"),
                // pw.Bullet(text: "Description : ${widget.hotel['description'] ?? 'Non fournie.'}"),

                // pw.SizedBox(height: 20),

                pw.Text(" Détails de la réservation",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Bullet(text: "Prix par nuit : ${widget.hotel['prix'].toString()} TND"),
                pw.Bullet(text: "Nombre de jours : $quantity"),
                pw.Bullet(
                  text: "Prix total : ${(widget.hotel['prix'] * quantity).toStringAsFixed(1)} TND",
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey700),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Date : ${DateTime.now().toLocal()}",
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final downloadsDir = Directory('/storage/emulated/0/Download');
    final file = File('${downloadsDir.path}/reservation.pdf');
    await file.writeAsBytes(await pdf.save());

    Get.snackbar('PDF généré', 'Fichier enregistré dans Téléchargements');
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.hotel['imageUrl'] as String? ?? '';
    final double prix = widget.hotel['prix']?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) => progress == null
                            ? child
                            : Center(
                                child: LoadingAnimationWidget.discreteCircle(
                                  size: 32,
                                  color: Colors.black,
                                  secondRingColor: Colors.indigo,
                                  thirdRingColor: Colors.pink.shade400,
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/default_hotel.jpg',
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/default_hotel.jpg',
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleBtn(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                      Row(
                        children: [
                          _circleBtn(icon: Icons.favorite_border),
                          const SizedBox(width: 10),
                          _circleBtn(icon: Icons.share),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.hotel['nom'] ?? "Nom d'hôtel",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('${prix.toStringAsFixed(1)} TND / nuit',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.hotel['localisation'] ?? "Localisation",
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const Text("4.9 (2.8k)", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _Feature(icon: Icons.king_bed, label: "2 Bed"),
                      _Feature(icon: Icons.bathtub, label: "2 Bath"),
                      _Feature(icon: Icons.ac_unit, label: "AC"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Description",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(widget.hotel['description'] ?? "Aucune description fournie.",
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (quantity > 1) setState(() => quantity--);
                        },
                        child: const Icon(Icons.remove_circle_outline),
                      ),
                      const SizedBox(width: 10),
                      Text(quantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => quantity++),
                        child: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _reserver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      'Réserver - ${(prix * quantity).toStringAsFixed(1)} TND',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Feature({required this.icon, required this.label, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }
}
