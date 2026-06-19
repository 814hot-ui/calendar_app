class CalendarCellData {
  int id;            
  DateTime date;     
  String memo;       
  List<String> emotions; 
  String? imagePath; 

  // 👇 이 부분을 아래처럼 정확하게 수정해 줍니다!
  CalendarCellData({
    required this.id,      // required 추가
    required this.date,    
    required this.memo,    
    required this.emotions,
    this.imagePath,
  });
}