class Vehicle {
  final String id;
  final String namaKendaraan;
  final String tipe;

  Vehicle({
    required this.id,
    required this.namaKendaraan,
    required this.tipe,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'].toString(),
      namaKendaraan: json['nama_kendaraan'],
      tipe: json['tipe'],
    );
  }
}
