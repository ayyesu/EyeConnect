import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  final String requestId;
  final String volunteerId;
  final int callDuration;

  const RatingDialog({
    super.key,
    required this.requestId,
    required this.volunteerId,
    required this.callDuration,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Experience'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How was your experience with the volunteer?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Semantics(
            label: 'Rating selector',
            hint: 'Double tap on a star to set your rating. Current rating is ${_rating.toInt()} out of 5 stars',
            child: MergeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return ExcludeSemantics(
                    child: IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1.0;
                        });
                        // Announce the new rating for screen readers
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Rating set to ${index + 1} stars',
                              semanticsLabel: 'You have selected ${index + 1} stars',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      tooltip: 'Rate ${index + 1} stars',
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Current rating display',
            value: '${_rating.toInt()} stars',
            child: Text(
              'Current rating: ${_rating.toInt()} stars',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        Semantics(
          button: true,
          label: 'Submit rating button',
          hint: 'Double tap to submit your rating of ${_rating.toInt()} stars',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(_rating),
            child: const Text('Submit Rating'),
          ),
        ),
      ],
    );
  }
}
