import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lotti/themes/theme.dart';
import 'package:lotti/widgets/app_bar/sliver_title_bar.dart';
import 'package:lotti/widgets/search/search_widget.dart';

class DefinitionsListPage<T> extends StatefulWidget {
  const DefinitionsListPage({
    required this.stream,
    required this.title,
    required this.getName,
    required this.definitionCard,
    required this.floatingActionButton,
    this.initialSearchTerm,
    super.key,
  });

  final Stream<List<T>> stream;
  final String title;
  final String Function(T) getName;
  final Widget Function(int index, T item) definitionCard;
  final Widget? floatingActionButton;
  final String? initialSearchTerm;

  @override
  State<DefinitionsListPage<T>> createState() => _DefinitionsListPageState();
}

class _DefinitionsListPageState<T> extends State<DefinitionsListPage<T>> {
  String match = '';

  @override
  void initState() {
    super.initState();

    setState(() {
      if (widget.initialSearchTerm != null) {
        match = '${widget.initialSearchTerm}';
      }
    });
  }

  Future<void> onQueryChanged(String query) async {
    setState(() {
      match = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: widget.stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<T>> snapshot,
      ) {
        final items = snapshot.data ?? [];
        final filtered = items
            .where(
              (T item) => widget.getName(item).toLowerCase().contains(match),
            )
            .sortedBy(widget.getName)
            .toList();

        return Scaffold(
          backgroundColor: styleConfig().negspace,
          floatingActionButton: widget.floatingActionButton,
          body: CustomScrollView(
            slivers: <Widget>[
              SliverTitleBar(
                widget.title,
                pinned: true,
                showBackButton: true,
              ),
              SliverToBoxAdapter(
                child: SearchWidget(
                  text: match,
                  onChanged: onQueryChanged,
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: List.generate(
                    filtered.length,
                    (int index) {
                      return widget.definitionCard(
                        index,
                        filtered.elementAt(index),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class FloatingAddIcon extends StatelessWidget {
  const FloatingAddIcon({
    required this.createFn,
    this.semanticLabel,
    super.key,
  });

  final void Function() createFn;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: styleConfig().primaryColor,
      onPressed: createFn,
      child: Icon(
        Icons.add,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
