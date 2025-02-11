import 'dart:io';
import 'package:mysql1/mysql1.dart';
import 'package:collection/collection.dart'; // Import the collection package for firstWhereOrNull
import 'dart:collection';

class Student {
  int id;
  String name;
  String phone;

  Student(this.id, this.name, this.phone);

  @override
  String toString() {
    return 'ID: $id, Name: $name, Phone: $phone';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

void main() async {
  Future<void> addStudent(MySqlConnection conn, HashSet<Student> students) async {
    print('Nhập tên sinh viên: ');
    String? name = stdin.readLineSync();
    if (name == null || name.isEmpty) {
      print('Tên không đúng định dạng');
      return;
    }
    print('Nhập số điện thoại sinh viên: ');
    String? phone = stdin.readLineSync();
    if (phone == null || phone.isEmpty) {
      print('SĐT không hợp lệ');
      return;
    }

    var result = await conn.query('INSERT INTO student (name, phone) VALUES (?, ?)', [name, phone]);
    var id = result.insertId;
    if (id != null) {
      students.add(Student(id, name, phone));
      print('Sinh viên đã được thêm!');
    } else {
      print('Thêm lỗi!!!');
    }
  }

  Future<void> editStudent(MySqlConnection conn, HashSet<Student> students) async {
    print('Nhập ID sinh viên cần sửa: ');
    String? idInput = stdin.readLineSync();
    int? id = int.tryParse(idInput ?? '');
    if (id == null) {
      print('ID không hợp lệ');
      return;
    }

    var student = students.firstWhereOrNull((s) => s.id == id);
    if (student == null) {
      print('Sinh viên không tồn tại');
      return;
    }

    print('Nhập tên sinh viên mới: ');
    String? name = stdin.readLineSync();
    if (name == null || name.isEmpty) {
      print('Tên không đúng định dạng');
      return;
    }

    print('Nhập số điện thoại sinh viên mới: ');
    String? phone = stdin.readLineSync();
    if (phone == null || phone.isEmpty) {
      print('SĐT không hợp lệ');
      return;
    }

    await conn.query('UPDATE student SET name = ?, phone = ? WHERE id = ?', [name, phone, id]);
    student.name = name;
    student.phone = phone;
    print('Sinh viên đã được sửa!');
  }

  Future<void> deleteStudent(MySqlConnection conn, HashSet<Student> students) async {
    print('Nhập ID sinh viên cần xóa: ');
    String? idInput = stdin.readLineSync();
    int? id = int.tryParse(idInput ?? '');
    if (id == null) {
      print('ID không hợp lệ');
      return;
    }

    var student = students.firstWhereOrNull((s) => s.id == id);
    if (student == null) {
      print('Sinh viên không tồn tại');
      return;
    }

    await conn.query('DELETE FROM student WHERE id = ?', [id]);
    students.removeWhere((s) => s.id == id);
    print('Sinh viên đã được xóa!');
  }

  Future<void> displayStudents(MySqlConnection conn, HashSet<Student> students) async {
    var results = await conn.query("SELECT id, name, phone FROM student");

    students.clear();

    for (var row in results) {
      students.add(Student(row['id'], row['name'], row['phone']));
    }
    if (students.isEmpty) {
      print('Danh sách sinh viên trống');
    } else {
      print('Danh sách sinh viên là:');
      for (var student in students) {
        print(student);
      }
    }
  }

  final settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    // password: ''
    db: 'school',
  );
  final conn = await MySqlConnection.connect(settings);

  HashSet<Student> students = HashSet<Student>();

  while (true) {
    print("""
    Menu:
    1. Thêm sinh viên
    2. Sửa sinh viên
    3. Xóa sinh viên
    4. Hiển thị danh sách sinh viên
    5. Thoát
    Chọn một thao tác: 
    """);

    String? choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        await addStudent(conn, students);
        break;
      case '2':
        await editStudent(conn, students);
        break;
      case '3':
        await deleteStudent(conn, students);
        break;
      case '4':
        await displayStudents(conn, students);
        break;
      case '5':
        await conn.close();
        exit(0);
      default:
        print('Lựa chọn không hợp lệ');
    }
  }
}
