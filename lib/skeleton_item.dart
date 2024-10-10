import 'package:flutter/material.dart';

class SkeletonItem extends StatelessWidget {
  const SkeletonItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 5),
                Container(
                  width: 250,
                  height: 10,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 5),
                Container(
                  width: 100,
                  height: 10,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}