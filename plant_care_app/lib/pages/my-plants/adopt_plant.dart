import 'package:flutter/material.dart';

class AdoptPlant extends StatelessWidget {
  final Map<String, dynamic> plant;

  const AdoptPlant({Key? key, required this.plant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adopt ${plant['species_name']}'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant details will go here
            Text(
              'Adoption details for ${plant['species_name']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            
            const SizedBox(height: 20),
            
            // Placeholder for adoption form
            Text(
              'This is a placeholder for the adoption form. You can add form fields here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}