import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/quickalert.dart';
import 'package:runqpp/hotelScreens/HotelDetailPage.dart';
import 'add_hotel.dart';
import 'edithotel.dart';
import '../shared/colors.dart';

class HotelListPage extends StatefulWidget {
  const HotelListPage({Key? key}) : super(key: key);

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  final TextEditingController searchController = TextEditingController();
  String searchText = "";
  bool isAdmin = false;
  bool loadingRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      setState(() {
        isAdmin = data?['role'] == 'admin';
        loadingRole = false;
      });
    } else {
      setState(() => loadingRole = false);
    }
  }

  void _confirmDelete(String id) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: 'Vous êtes sûr de supprimer cet hôtel ?',
      confirmBtnText: 'Oui',
      cancelBtnText: 'Non',
      onConfirmBtnTap: () async {
        await FirebaseFirestore.instance.collection('hotels').doc(id).delete();
        Navigator.of(context).pop(); // fermer l'alerte
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingRole) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.discreteCircle(
            size: 32,
            color: Colors.black,
            secondRingColor: Colors.indigo,
            thirdRingColor: Colors.pink.shade400,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Liste des Hôtels",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey.shade100,
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () => Get.to(() => const AddHotelPage()),
              icon: const Icon(Icons.add_circle_outline),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) =>
                  setState(() => searchText = value.toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher par localisation...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),

          // liste des hôtels
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hotels')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.discreteCircle(
                      size: 32,
                      color: Colors.black,
                      secondRingColor: Colors.indigo,
                      thirdRingColor: Colors.pink.shade400,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['localisation'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(searchText);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                      child:
                          Text("Aucun hôtel ne correspond à la recherche."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final hotel = doc.data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          if (isAdmin) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditHotelPage(
                                  hotelId: doc.id,
                                  hotel: hotel,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HotelDescriptionPage(hotel: hotel),
                              ),
                            );
                          }
                        },
                        child: HotelCard(
                          hotel: hotel,
                          isAdmin: isAdmin,
                          onDelete: () => _confirmDelete(doc.id),
                        ),
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

class HotelCard extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final bool isAdmin;
  final VoidCallback onDelete;

  const HotelCard({
    Key? key,
    required this.hotel,
    required this.isAdmin,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = hotel['imageUrl'] as String? ?? '';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // image depuis Storage
          imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Center(
                          child: LoadingAnimationWidget.discreteCircle(
                            size: 24,
                            color: Colors.black,
                            secondRingColor: Colors.indigo,
                            thirdRingColor: Colors.pink.shade400,
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/hotel.jpg',
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  'assets/images/hotel.jpg',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),

          // infos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // gauche : nom, localisation, note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel['nom'] ?? 'Sans nom',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hotel['localisation'] ?? 'Non précisée',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.star,
                              size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text("4.9 (2.8k)",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),

                // droite : prix + icône
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${hotel['prix']} TND',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Text('/nuit',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    if (isAdmin)
                      IconButton(
                        icon:
                            const Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                      )
                    else
                      const SizedBox(width: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
