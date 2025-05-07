import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../shared/colors.dart';

class ReservationPage extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const ReservationPage({super.key, required this.hotel});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTimeRange? selectedRange;
  int selectedGuests = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedRange = DateTimeRange(
      start: now,
      end: now.add(const Duration(days: 1)),
    );
  }

  Future<void> reserver() async {
    if (selectedRange == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar("Erreur", "Veuillez vous connecter pour réserver.");
      return;
    }

    final nombreDeNuits = selectedRange!.end.difference(selectedRange!.start).inDays;
    final prixTotal = (widget.hotel['prix'] ?? 0.0) * nombreDeNuits;

    await FirebaseFirestore.instance.collection('reservations').add({
      'user_id': user.uid,
      'hotel_nom': widget.hotel['nom'],
      'hotel_localisation': widget.hotel['localisation'],
      'prix_par_nuit': widget.hotel['prix'],
      'date_debut': selectedRange!.start.toIso8601String(),
      'date_fin': selectedRange!.end.toIso8601String(),
      'nombre_de_nuits': nombreDeNuits,
      'nombre_guests': selectedGuests,
      'created_at': Timestamp.now(),
    });

    Get.snackbar("Succès", "Réservation effectuée avec succès !");
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final prix = widget.hotel['prix'] ?? 0.0;
    final nombreDeNuits = selectedRange!.end.difference(selectedRange!.start).inDays;
    final prixTotal = (prix * nombreDeNuits).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Réserver"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Date de réservation",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 🗓️ Affichage direct du calendrier
            CalendarDatePicker(
              initialDate: selectedRange!.start,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onDateChanged: (newDate) {
                setState(() {
                  selectedRange = DateTimeRange(
                    start: newDate,
                    end: newDate.add(const Duration(days: 1)),
                  );
                });
              },
            ),

            const SizedBox(height: 16),
            const Text("Nombre d'invités",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 🧍 Sélection du nombre d'invités
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(10, (index) {
                  final guest = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => selectedGuests = guest),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedGuests == guest
                            ? mainColor
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        guest.toString(),
                        style: TextStyle(
                          color: selectedGuests == guest
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),
            // ✅ Bouton de réservation
            ElevatedButton(
              onPressed: reserver,
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text("Réserver maintenant - $prixTotal TND"),
            ),
          ],
        ),
      ),
    );
  }
}
