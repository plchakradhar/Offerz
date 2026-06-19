import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final String currentLocation;
  const LocationPickerScreen({super.key, required this.currentLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, String>> _searchResults = [];
  List<dynamic> _savedAddresses = [];
  bool _isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    bool isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      String mobile = await AuthService.getUserMobile();
      if (mobile.isNotEmpty) {
        final profileRes = await ProfileService.getProfile(mobile);
        if (profileRes['success'] && profileRes['data']['addresses'] != null) {
          if (mounted) {
            setState(() {
              _savedAddresses = profileRes['data']['addresses'];
              _isLoadingAddresses = false;
            });
          }
          return;
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 2) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });
    final results = await LocationService.searchLocations(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLoading = true;
    });
    // This will request permissions if needed
    String city = await LocationService.getCurrentCity();
    if (city.startsWith("Lat:")) {
      city = "Unknown Location";
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context, city);
    }
  }

  void _selectLocation(String city) {
    Navigator.pop(context, city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Enter your city, town, or village",
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search for your city, town, or village...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged("");
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // Search Results or Default View
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildDefaultView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No results found",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined, color: Colors.black54),
          ),
          title: Text(
            result['city'] ?? "",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            result['displayName'] ?? "",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _selectLocation(result['city'] ?? "Unknown"),
        );
      },
    );
  }

  Widget _buildDefaultView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Current Location Button
        InkWell(
          onTap: _detectLocation,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.orange),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Use current location",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.currentLocation == "Fetching location..." 
                          ? "Using GPS"
                          : widget.currentLocation,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Saved Addresses Title
        Row(
          children: [
            const Icon(Icons.bookmark_border, color: Colors.black54, size: 20),
            const SizedBox(width: 8),
            Text(
              "SAVED ADDRESSES",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingAddresses)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.orange)))
        else if (_savedAddresses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text("No saved addresses found.", style: TextStyle(color: Colors.grey.shade600)),
          )
        else
          ..._savedAddresses.map((address) {
            String fullAddress = [
              address['doorNumber'],
              address['street'],
              address['city'],
              address['state'],
              address['zipcode']
            ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

            return Column(
              children: [
                _buildSavedAddressItem(
                  icon: Icons.location_on_outlined,
                  title: address['city'] ?? "Saved Address",
                  subtitle: fullAddress,
                  city: address['city'],
                ),
                const Divider(height: 1, color: Colors.black12),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildSavedAddressItem({required IconData icon, required String title, required String subtitle, String? city}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
        ),
      ),
      onTap: () {
        if (city != null && city.isNotEmpty) {
          _selectLocation(city);
        } else {
          final parts = subtitle.split(',');
          final extractedCity = parts.length > 2 ? parts[parts.length - 3].trim() : parts.last.trim();
          _selectLocation(extractedCity);
        }
      },
    );
  }
}
