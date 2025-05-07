import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:runqpp/shared/colors.dart';

class UserReservationListPage extends StatefulWidget {
  const UserReservationListPage({Key? key}) : super(key: key);

  @override
  State<UserReservationListPage> createState() => _UserReservationListPageState();
}

class _UserReservationListPageState extends State<UserReservationListPage> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? '';
  }

  Future<void> _deleteReservation(String docId) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: 'Voulez-vous vraiment supprimer cette réservation ?',
      confirmBtnText: 'Oui',
      cancelBtnText: 'Non',
      onConfirmBtnTap: () async {
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(docId)
            .delete();
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _editReservationDialog(String docId, int currentNights, double pricePerNight) async {
    int nights = currentNights;
    final totalController = TextEditingController(text: (nights * pricePerNight).toStringAsFixed(1));

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFF5F0FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Modifier la réservation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prix par nuit : ${pricePerNight.toStringAsFixed(1)} TND',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: mainColor),
                        onPressed: nights > 1
                            ? () => setState(() {
                                  nights--;
                                  totalController.text = (nights * pricePerNight).toStringAsFixed(1);
                                })
                            : null,
                      ),
                      Text(
                        '$nights nuit${nights > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: mainColor),
                        onPressed: () => setState(() {
                          nights++;
                          totalController.text = (nights * pricePerNight).toStringAsFixed(1);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: totalController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Prix total (TND)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(color: mainColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('reservations')
                              .doc(docId)
                              .update({
                            'nbrJours': nights,
                            'prixTotal': nights * pricePerNight,
                          });
                          Navigator.of(context).pop();
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            text: 'Réservation mise à jour !',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Réservations',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('userId', isEqualTo: _userId)

            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Vous n\'avez aucune réservation.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final hotelNom = data['hotelNom'] as String? ?? '';
              final int nights = data['nbrJours'] as int? ?? 0;
              final double total = (data['prixTotal'] as num? ?? 0).toDouble();
              final ts = data['dateReservation'] as Timestamp;
              final date = ts.toDate();
              final formattedDate = DateFormat('dd/MM/yyyy – HH:mm').format(date);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _editReservationDialog(doc.id, nights, total / nights),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📌 ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              hotelNom,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                         
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('📝 ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              '$nights nuit${nights > 1 ? 's' : ''} • ${total.toStringAsFixed(1)} TND',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: InkWell(
                               onTap: () => _deleteReservation(doc.id),
                              child: Icon(Icons.delete, color: Colors.red)),
                          ),
                        
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          formattedDate,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
