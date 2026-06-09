class Utils {
  // Android emulator → 10.0.2.2 | Dispositivo físico → IP do PC na rede local
  static String ip_servidor = 'localhost:5000'; // emulador Android → 10.0.2.2:5000 | físico → IP do PC
  static String baseUrl = 'http://$ip_servidor/api/v1';
}
