import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final Future<List<String>> Function(String query)? onSuggestions;
  final List<String> recentSearches;
  final VoidCallback? onClearHistory;

  const CustomSearchBar({
    super.key,
    required this.onSearch,
    this.onSuggestions,
    this.recentSearches = const [],
    this.onClearHistory,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions(String value) async {
    if (widget.onSuggestions == null || value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);
    final suggestions = await widget.onSuggestions!(value);
    if (!mounted || _controller.text.trim() != value.trim()) return;

    setState(() {
      _suggestions = suggestions;
      _isSearching = false;
    });
  }

  void _submit(String city) {
    final value = city.trim();
    if (value.isEmpty) return;

    _controller.text = value;
    _focusNode.unfocus();
    setState(() => _suggestions = []);
    widget.onSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    final showPanel =
        _focusNode.hasFocus &&
        (_suggestions.isNotEmpty || widget.recentSearches.isNotEmpty);

    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.search,
          onChanged: _loadSuggestions,
          onSubmitted: _submit,
          decoration: InputDecoration(
            hintText: 'Search any city',
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.18),
            prefixIcon: const Icon(Icons.travel_explore, color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _submit(_controller.text),
                  ),
          ),
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: showPanel
              ? Container(
                  key: const ValueKey('search-panel'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_suggestions.isNotEmpty) ...[
                        const _PanelTitle(title: 'Suggestions'),
                        ..._suggestions.map(
                          (city) => _SearchOption(
                            icon: Icons.location_city,
                            title: city,
                            onTap: () => _submit(city),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Expanded(
                              child: _PanelTitle(title: 'Recent searches'),
                            ),
                            if (widget.onClearHistory != null)
                              TextButton(
                                onPressed: widget.onClearHistory,
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                        ...widget.recentSearches.map(
                          (city) => _SearchOption(
                            icon: Icons.history,
                            title: city,
                            onTap: () => _submit(city),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String title;

  const _PanelTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SearchOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SearchOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minLeadingWidth: 24,
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}
