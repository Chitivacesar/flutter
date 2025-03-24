import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C6E91),
          primary: const Color(0xFF2C6E91),
          secondary: const Color(0xFF4DABAA),
          background: const Color(0xFFF4F7F9),
        ),
        fontFamily: 'Montserrat',
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: const Color(0xFF2C6E91),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          bodyLarge: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 16,
          ),
        ),
      ),
      home: const DataListMedicaments(),
    );
  }
}

class DataListMedicaments extends StatefulWidget {
  const DataListMedicaments({super.key});

  @override
  State<DataListMedicaments> createState() => _DataListMedicamentsState();
}

class _DataListMedicamentsState extends State<DataListMedicaments>
    with SingleTickerProviderStateMixin {
  List<dynamic> data = [], dataFilter = [], favoriteMedicaments = [];
  bool isLoading = true;
  final searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool isFavoritesView = false;
  bool isAscending = true;

  bool get isSearching => searchController.text.isNotEmpty;

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse('https://www.datos.gov.co/resource/xzwx-qpja.json'));
      if (response.statusCode == 200) {
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {
          data = json.decode(response.body);
          dataFilter = data;
          isLoading = false;
          _animationController.forward();
        });
      } else {
        _showErrorSnackBar('Error al cargar los datos');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Error de conexión. Intente más tarde.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'REINTENTAR',
          textColor: Colors.white,
          onPressed: fetchData,
        ),
      ),
    );
  }

  void filterData(String query) {
    setState(() {
      dataFilter = query.isEmpty
          ? data
          : data.where((item) {
              final principioActivo = (item['principioactivo'] ?? '').toLowerCase();
              final formafarmaceutica = (item['formafarmaceutica'] ?? '').toLowerCase();
              final searchLower = query.toLowerCase();
              return principioActivo.contains(searchLower) ||
                  formafarmaceutica.contains(searchLower);
            }).toList();
    });
  }

  void sortData() {
    setState(() {
      dataFilter.sort((a, b) {
        String principioA = a['principioactivo'].toString().toLowerCase();
        String principioB = b['principioactivo'].toString().toLowerCase();
        return isAscending
            ? principioA.compareTo(principioB)
            : principioB.compareTo(principioA);
      });
      isAscending = !isAscending;
    });
  }

  void toggleFavoritesView() {
    setState(() {
      isFavoritesView = !isFavoritesView;
    });
  }

  void addToFavorites(dynamic medication) {
    setState(() {
      if (!favoriteMedicaments.contains(medication)) {
        favoriteMedicaments.add(medication);
      }
    });
  }

  void removeFromFavorites(dynamic medication) {
    setState(() {
      favoriteMedicaments.remove(medication);
    });
  }

  void _showMedicationDetails(dynamic medication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            children: [
              _buildBottomSheetHeader(medication),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      icon: Icons.medical_services_rounded,
                      label: 'Forma Farmacéutica',
                      value: medication['formafarmaceutica'] ?? 'No disponible',
                    ),
                    _buildDetailCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Concentración',
                      value: medication['concentracion'] ?? 'No disponible',
                    ),
                    if (medication['viaadministracion'] != null)
                      _buildDetailCard(
                        icon: Icons.directions_rounded,
                        label: 'Vía de Administración',
                        value: medication['viaadministracion'],
                      ),
                    if (medication['laboratorio'] != null)
                      _buildDetailCard(
                        icon: Icons.corporate_fare_rounded,
                        label: 'Laboratorio',
                        value: medication['laboratorio'],
                      ),
                    if (medication['atc'] != null)
                      _buildDetailCard(
                        icon: Icons.qr_code_rounded,
                        label: 'Código ATC',
                        value: medication['atc'],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    addToFavorites(medication);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Medicamento guardado en favoritos'),
                        backgroundColor: const Color(0xFF2C6E91),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                  label: const Text('Guardar en Favoritos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C6E91),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetHeader(dynamic medication) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C6E91).withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medication['principioactivo'] ?? 'Medicamento',
            style: const TextStyle(
              color: Color(0xFF2C6E91),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            medication['formafarmaceutica'] ?? 'Detalles del medicamento',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF2C6E91),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_rounded,
              color: const Color(0xFF2C6E91),
              size: 30,
            ),
            const SizedBox(width: 10),
            Text(
              'MediSearch',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          _buildActionButton(
            icon: isFavoritesView 
              ? Icons.list_rounded 
              : Icons.favorite_rounded,
            onPressed: toggleFavoritesView,
            tooltip: isFavoritesView ? 'Ver Lista' : 'Ver Favoritos',
          ),
          _buildActionButton(
            icon: isAscending 
              ? Icons.sort_by_alpha_rounded 
              : Icons.sort_rounded,
            onPressed: sortData,
            tooltip: 'Ordenar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: isLoading
                ? _buildLoadingIndicator()
                : isFavoritesView
                    ? _buildFavoriteMedicationsView()
                    : _buildMedicamentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required VoidCallback onPressed, 
    required String tooltip
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: const Color(0xFF2C6E91),
          ),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C6E91).withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: filterData,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Buscar medicamento...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: const Color(0xFF2C6E91).withOpacity(0.7),
            ),
            suffixIcon: isSearching
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                    onPressed: () {
                      searchController.clear();
                      filterData('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: _buildInputBorder(),
            enabledBorder: _buildInputBorder(),
            focusedBorder: _buildInputBorder(
              color: const Color(0xFF2C6E91),
              width: 2,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16, 
              horizontal: 16
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _buildInputBorder({
    Color? color, 
    double width = 0
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: color ?? Colors.transparent,
        width: width,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF2C6E91),
            strokeWidth: 4,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando medicamentos...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicamentsList() {
    if (dataFilter.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron medicamentos',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        itemCount: dataFilter.length,
        itemBuilder: (context, index) {
          final medication = dataFilter[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C6E91).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 12
                ),
                title: Text(
                  medication['principioactivo'] ?? 'No disponible',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                subtitle: Text(
                  medication['formafarmaceutica'] ?? 'No disponible',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF2C6E91).withOpacity(0.7),
                ),
                onTap: () => _showMedicationDetails(medication),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteMedicationsView() {
    return favoriteMedicaments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes medicamentos favoritos',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: favoriteMedicaments.length,
            itemBuilder: (context, index) {
              final medication = favoriteMedicaments[index];
              return Dismissible(
                key: Key(medication['principioactivo']),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  removeFromFavorites(medication);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C6E91).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 12
                      ),
                      title: Text(
                        medication['principioactivo'] ?? 'No disponible',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      subtitle: Text(
                        medication['formafarmaceutica'] ?? 'No disponible',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: const Color(0xFF2C6E91).withOpacity(0.7),
                      ),
                      onTap: () => _showMedicationDetails(medication),
                    ),
                  ),
                ),
              );
            },
          );
  }
}