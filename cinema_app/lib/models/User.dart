class User {
  int id = 0;
  String username = "";
  String email = "";
  String password = "";
  String role = "user";       
  bool status = true;          
  DateTime createdAt = DateTime.now();

  void showInfo() {
    print("ID: $id");
    print("Username: $username");
    print("Email: $email");
    print("Role: $role");
    print("Status: $status");
  }

  void setUser(int setId, String setUsername, String setEmail, String setPassword) {
    id = setId;
    username = setUsername;
    email = setEmail;
    password = setPassword;
  }

  bool isAdmin() {
    return role == "admin";
  }
}

