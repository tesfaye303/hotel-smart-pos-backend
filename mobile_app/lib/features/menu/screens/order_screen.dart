ElevatedButton(
  onPressed: () async {
    final orderService = OrderService();
    
    // ትዕዛዙን መላክ (የኦንላይን እና ኦፍላይን ሁኔታን ያረጋግጣል)
    bool isOnline = await orderService.sendOrder(newOrderMap);

    if (!context.mounted) return;

    if (isOnline) {
      // 1. ኦንላይን ከሆነ ለተጠቃሚው የስኬት መልዕክት ማሳየት
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ትዕዛዙ ወደ ወጥ ቤት ተልኳል!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // 2. ኦፍላይን ከሆነ በስልኩ መቀመጡን ማሳወቅ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ኔትወርክ ስለሌለ ትዕዛዙ በስልኩ ላይ ተቀምጧል፤ Wi-Fi ሲመለስ ይላካል።'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  },
  child: const Text('ትዕዛዝ ላክ'),
)