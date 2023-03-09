class MenusListData {
  MenusListData({
    this.imagePath = '',
    this.titleTxt = '',
    this.startColor = '',
    this.endColor = '',
    this.description,
  });

  String imagePath;
  String titleTxt;
  String startColor;
  String endColor;
  List<String>? description;

  static List<MenusListData> tabIconsList = <MenusListData>[
    MenusListData(
      imagePath: 'assets/images/pic/maintenance.png',
      titleTxt: 'Setup',
      description: <String>['Setup build'],
      startColor: '#FA7D82',
      endColor: '#FFB295',
    ),
    MenusListData(
      imagePath: 'assets/images/pic/refresh2.png',
      titleTxt: 'Backup',
      description: <String>['Backup current build'],
      startColor: '#738AE6',
      endColor: '#5C5EDD',
    ),
    MenusListData(
      imagePath: 'assets/images/pic/refresh4.png',
      titleTxt: 'Restore',
      description: <String>['Restore to a backed up build'],
      startColor: '#FE95B6',
      endColor: '#FF5287',
    ),
  ];
}
