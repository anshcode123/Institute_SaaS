import 'package:flutter/material.dart';

enum RecordViewMode { list, grid }

class GridListToggle extends StatelessWidget {
  const GridListToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RecordViewMode value;
  final ValueChanged<RecordViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RecordViewMode>(
      segments: const [
        ButtonSegment(value: RecordViewMode.grid, icon: Icon(Icons.grid_view)),
        ButtonSegment(value: RecordViewMode.list, icon: Icon(Icons.view_list)),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
      ),
    );
  }
}

class ResponsiveRecordGrid extends StatelessWidget {
  const ResponsiveRecordGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 800
                ? 3
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
        return GridView.builder(
          padding:
              const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 80),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 4.2 : 1.45,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
