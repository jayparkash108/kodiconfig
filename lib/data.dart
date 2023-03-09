import 'package:flutter/material.dart';

class Statistics {
  final String title;
  final String number;

  Statistics({
    required this.title,
    required this.number,
  });
}


final List<Statistics> statistics = [
  Statistics(
    title: "Builds backups",
    number: "02",
  ),
  Statistics(
    title: "Builds Restored",
    number: "250",
  ),
  Statistics(
    title: "Builds backups",
    number: "02",
  ),
  Statistics(
    title: "Builds Restored",
    number: "250",
  ),
];
