class MyUser {
  String? uid;
  String? email;
  String? firstName;
  String? phoneNumber;
  String? address;
  int? availableSeats;

  MyUser(this.uid);
  MyUser.full(this.uid, this.email, this.firstName, this.phoneNumber,
      this.address, this.availableSeats);
}
