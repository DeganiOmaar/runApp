import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationListPage extends StatefulWidget {
  const ReservationListPage({Key? key}) : super(key: key);

  @override
  _ReservationListPageState createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  List<String> _hotelNames = [];
  String _selectedHotel = 'Tous';
  bool _loadingHotels = true;

  @override
  void initState() {
    super.initState();
    _fetchHotelNames();
  }

  Future<void> _fetchHotelNames() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('hotels')
        .orderBy('nom')
        .get();
    setState(() {
      _hotelNames = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['nom'] as String)
          .toList();
      _hotelNames.insert(0, 'Tous');
      _loadingHotels = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingHotels) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Liste des Réservations",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // 🔽 Dropdown stylé
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  value: _selectedHotel,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  dropdownColor: Colors.white,
                  items: _hotelNames.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedHotel = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ),

          // 📄 Liste filtrée
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reservations')
                  .orderBy('dateReservation', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final hotelNom = (data['hotelNom'] ?? '').toString();
                  return _selectedHotel == 'Tous' || hotelNom == _selectedHotel;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Aucune réservation.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final data = filtered[i].data() as Map<String, dynamic>;
                    final userNom = data['nomUtilisateur'] ?? '';
                    final userPrenom = data['prenomUtilisateur'] ?? '';
                    final hotelNom = data['hotelNom'] ?? '';
                    final int nights = data['nbrJours'] as int? ?? 0;
                    final double total =
                        (data['prixTotal'] as num? ?? 0).toDouble();
                    final ts = data['dateReservation'] as Timestamp;
                    final date = ts.toDate();
                    final formattedDate =
                        DateFormat('dd/MM/yyyy – HH:mm').format(date);

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$userNom $userPrenom',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('📌 ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  'Hôtel : $hotelNom',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('📝 ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  '$nights nuit${nights > 1 ? 's' : ''} • ${total.toStringAsFixed(1)} TND',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
