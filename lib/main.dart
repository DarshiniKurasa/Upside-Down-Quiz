import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

// Add this global audio service
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer themePlayer = AudioPlayer();
  final AudioPlayer effectsPlayer = AudioPlayer();
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  Future<void> playTheme() async {
    await themePlayer.stop(); // Stop if already playing
    await themePlayer.play(AssetSource('audio/theme.mp3'));
    themePlayer.setReleaseMode(ReleaseMode.loop); // Make it loop continuously
  }

  Future<void> playSound(String soundPath) async {
    if (!_isMuted) {
      await effectsPlayer.play(AssetSource(soundPath));
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      themePlayer.setVolume(0);
    } else {
      themePlayer.setVolume(1);
    }
  }

  void dispose() {
    themePlayer.dispose();
    effectsPlayer.dispose();
  }
}

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AudioService audioService = AudioService();

  @override
  void initState() {
    super.initState();
    // Start the theme music when app starts
    audioService.playTheme();
  }

  @override
  void dispose() {
    // Clean up resources when app is closed
    audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stranger Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.red.shade700,
          secondary: Colors.red.shade300,
          surface: Colors.grey.shade900,
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontFamily: 'BenguiatITCBold',
            fontSize: 36,
            color: Colors.red,
            letterSpacing: 2.0,
          ),
          bodyLarge: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 16,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'BenguiatITCBold',
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  final AudioService audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Note: We don't play theme here anymore, it's played in MyApp
    _controller.forward();
    
    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Don't dispose audio here, it's handled by the AudioService
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 300,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "STRANGER QUIZ",
                    style: TextStyle(
                      fontFamily: 'BenguiatITCBold',
                      fontSize: 32,
                      color: Colors.red,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const CircularProgressIndicator(
                    color: Colors.red,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isUpsideDown = false;
  final AudioService audioService = AudioService();

  void _playClickSound() {
    audioService.playSound('audio/click.mp3');
  }

  void _toggleUpsideDown() {
    setState(() {
      _isUpsideDown = !_isUpsideDown;
    });
    audioService.playSound('audio/dimension_shift.mp3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              _isUpsideDown 
                ? 'assets/images/upside_down_bg.jpg' 
                : 'assets/images/hawkins_bg.jpg'
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(_isUpsideDown ? 0.5 : 0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: _buildMenuOptions(),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDimensionSwitcher(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "STRANGER QUIZ",
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          _isUpsideDown ? "THE UPSIDE DOWN" : "HAWKINS, INDIANA - 1986",
          style: TextStyle(
            color: Colors.grey.shade400,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOptions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMenuButton(
          "START QUEST", 
          Icons.play_arrow_rounded,
          () {
            _playClickSound();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(isUpsideDown: _isUpsideDown),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildMenuButton(
          "CHARACTER PROFILES", 
          Icons.person_outline,
          () {
            _playClickSound();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharactersScreen(isUpsideDown: _isUpsideDown),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildMenuButton(
          "SETTINGS", 
          Icons.settings,
          () {
            _playClickSound();
            showDialog(
              context: context,
              builder: (_) => SettingsDialog(isUpsideDown: _isUpsideDown),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: _isUpsideDown ? Colors.teal.shade900.withOpacity(0.8) : Colors.red.shade900.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _isUpsideDown ? Colors.teal.shade200 : Colors.red.shade200,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _isUpsideDown ? Colors.teal.shade100 : Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'BenguiatITCBold',
                fontSize: 18,
                letterSpacing: 1.5,
                color: _isUpsideDown ? Colors.teal.shade100 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionSwitcher() {
    return GestureDetector(
      onTap: _toggleUpsideDown,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: _isUpsideDown 
              ? Colors.teal.shade900.withOpacity(0.6) 
              : Colors.red.shade900.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isUpsideDown ? Colors.teal.shade200 : Colors.red.shade200,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isUpsideDown ? Icons.arrow_upward : Icons.arrow_downward,
              color: _isUpsideDown ? Colors.teal.shade100 : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              _isUpsideDown ? "RETURN TO HAWKINS" : "ENTER THE UPSIDE DOWN",
              style: TextStyle(
                fontFamily: 'BenguiatITCBold',
                color: _isUpsideDown ? Colors.teal.shade100 : Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final bool isUpsideDown;
  
  const QuizScreen({Key? key, required this.isUpsideDown}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedAnswerIndex;
  final AudioService audioService = AudioService();
  
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is the name of Eleven\'s biological father?',
      'answers': ['Martin Brenner', 'Jim Hopper', 'Terry Ives', 'Andrew Rich'],
      'correctIndex': 0,
    },
    {
      'question': 'What game were the boys playing when Will disappeared?',
      'answers': ['Monopoly', 'Dungeons & Dragons', 'Chess', 'Risk'],
      'correctIndex': 1,
    },
    {
      'question': 'What is the Demogorgon\'s favorite food?',
      'answers': ['Eggos', 'Humans', 'Blood', 'Cats'],
      'correctIndex': 2,
    },
    {
      'question': 'What is the name of the lab where Eleven grew up?',
      'answers': ['Hawkins National Laboratory', 'Starcourt Lab', 'Department of Energy', 'MKUltra Facility'],
      'correctIndex': 0,
    },
    {
      'question': 'What song does Jonathan play to help Will find his way back?',
      'answers': ['Should I Stay or Should I Go', 'Every Breath You Take', 'Africa', 'Running Up That Hill'],
      'correctIndex': 0,
    },
    {
      'question': 'What is the Mind Flayer also known as?',
      'answers': ['The Upside Down Monster', 'The Shadow Monster', 'The Spider Monster', 'The Demogorgon King'],
      'correctIndex': 1,
    },
    {
      'question': 'What is Lucas\'s weapon of choice?',
      'answers': ['Baseball bat with nails', 'Slingshot', 'Fireworks', 'Knife'],
      'correctIndex': 1,
    },
    {
      'question': 'What does Dustin name the Demodog he finds?',
      'answers': ['Dart', 'Demo', 'Yertle', 'Tadpole'],
      'correctIndex': 0,
    },
  ];

  void _checkAnswer(int selectedIndex) {
    if (_answered) return;
    
    setState(() {
      _selectedAnswerIndex = selectedIndex;
      _answered = true;
      
      if (selectedIndex == _questions[_currentQuestionIndex]['correctIndex']) {
        _score++;
        audioService.playSound('audio/correct.mp3');
      } else {
        audioService.playSound('audio/wrong.mp3');
      }
    });
    
    // Wait before moving to next question
    Timer(const Duration(seconds: 2), () {
      setState(() {
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
          _answered = false;
          _selectedAnswerIndex = null;
        } else {
          // Quiz finished
          _showResults();
        }
      });
    });
  }
  
  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isUpsideDown ? Colors.teal.shade900 : Colors.red.shade900,
        title: const Text(
          'QUEST COMPLETE',
          style: TextStyle(
            fontFamily: 'BenguiatITCBold',
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score: $_score/${_questions.length}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _getRankingMessage(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'RETURN TO BASE',
              style: TextStyle(
                fontFamily: 'BenguiatITCBold',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _getRankingMessage() {
    String message;
    String imagePath;
    
    if (_score == _questions.length) {
      message = 'Incredible! You are a true hero of Hawkins!';
      imagePath = 'assets/images/eleven_power.png';
    } else if (_score >= _questions.length * 0.75) {
      message = 'Great job! The party would be proud!';
      imagePath = 'assets/images/party.png';
    } else if (_score >= _questions.length * 0.5) {
      message = 'Not bad! You\'d survive in Hawkins.';
      imagePath = 'assets/images/demogorgon.png';
    } else {
      message = 'The Mind Flayer got you! Better luck next time!';
      imagePath = 'assets/images/mind_flayer.png';
    }
    
    return Column(
      children: [
        Image.asset(
          imagePath,
          height: 120,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isUpsideDown ? "UPSIDE DOWN QUEST" : "HAWKINS QUEST",
          style: const TextStyle(
            fontFamily: 'BenguiatITCBold',
            fontSize: 20,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              widget.isUpsideDown 
                ? 'assets/images/upside_down_bg.jpg' 
                : 'assets/images/hawkins_bg.jpg'
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(widget.isUpsideDown ? 0.5 : 0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildProgressBar(),
                const SizedBox(height: 20),
                _buildQuestionCard(currentQuestion),
                const SizedBox(height: 20),
                _buildAnswerOptions(currentQuestion),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    return Row(
      children: [
        Text(
          'Question ${_currentQuestionIndex + 1}/${_questions.length}',
          style: TextStyle(
            color: widget.isUpsideDown ? Colors.teal.shade100 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentQuestionIndex + 1) / _questions.length,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isUpsideDown ? Colors.teal : Colors.red,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isUpsideDown ? Colors.teal.shade900 : Colors.red.shade900,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Score: $_score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isUpsideDown 
            ? Colors.teal.shade900.withOpacity(0.8) 
            : Colors.red.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isUpsideDown ? Colors.teal.shade200 : Colors.red.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isUpsideDown ? Colors.teal.withOpacity(0.3) : Colors.red.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "STRANGE QUESTION",
            style: TextStyle(
              fontFamily: 'BenguiatITCBold',
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question['question'],
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnswerOptions(Map<String, dynamic> question) {
    List<String> answers = question['answers'];
    
    return Expanded(
      child: ListView.builder(
        itemCount: answers.length,
        itemBuilder: (context, index) {
          final bool isCorrect = _answered && index == question['correctIndex'];
          final bool isWrong = _answered && _selectedAnswerIndex == index && !isCorrect;
          
          return GestureDetector(
            onTap: () => _checkAnswer(index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withOpacity(0.7)
                    : isWrong
                        ? Colors.red.withOpacity(0.7)
                        : (widget.isUpsideDown 
                            ? Colors.teal.shade800.withOpacity(0.6)
                            : Colors.red.shade800.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrect
                      ? Colors.green.shade200
                      : isWrong
                          ? Colors.red.shade200
                          : (widget.isUpsideDown 
                              ? Colors.teal.shade100 
                              : Colors.red.shade100),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: isCorrect
                        ? Colors.green.shade300
                        : isWrong
                            ? Colors.red.shade300
                            : (widget.isUpsideDown 
                                ? Colors.teal.shade300 
                                : Colors.red.shade300),
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      answers[index],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_answered) 
                    Icon(
                      isCorrect ? Icons.check_circle : (isWrong ? Icons.cancel : null),
                      color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Update SettingsDialog to use the AudioService
class SettingsDialog extends StatefulWidget {
  final bool isUpsideDown;

  const SettingsDialog({Key? key, required this.isUpsideDown})
    : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _difficulty = 1.0; // 0 = easy, 1 = normal, 2 = hard
  final AudioService audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              widget.isUpsideDown ? Colors.teal.shade900 : Colors.red.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                widget.isUpsideDown
                    ? Colors.teal.shade100
                    : Colors.red.shade100,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "SETTINGS",
              style: TextStyle(
                fontFamily: 'BenguiatITCBold',
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingRow(
              "Sound Effects",
              Switch(
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                  // Toggle theme music
                  audioService.toggleMute();
                },
                activeColor: widget.isUpsideDown ? Colors.teal : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingRow(
              "Vibration",
              Switch(
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                },
                activeColor: widget.isUpsideDown ? Colors.teal : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingRow(
              "Difficulty",
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDifficultyLabel(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: _difficulty,
                      min: 0,
                      max: 2,
                      divisions: 2,
                      activeColor:
                          widget.isUpsideDown ? Colors.teal : Colors.red,
                      onChanged: (value) {
                        setState(() {
                          _difficulty = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            widget.isUpsideDown
                                ? Colors.teal.shade100
                                : Colors.red.shade100,
                      ),
                    ),
                    child: const Text(
                      "CLOSE",
                      style: TextStyle(
                        fontFamily: 'BenguiatITCBold',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyLabel() {
    if (_difficulty == 0) {
      return "Easy";
    } else if (_difficulty == 1) {
      return "Normal";
    } else {
      return "Hard";
    }
  }

  Widget _buildSettingRow(String label, Widget control) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        control,
      ],
    );
  }
}

class CharactersScreen extends StatelessWidget {
  final bool isUpsideDown;
  final AudioService audioService = AudioService();

  CharactersScreen({Key? key, required this.isUpsideDown}) : super(key: key);

  final List<Map<String, dynamic>> _characters = [
    {
      'name': 'Eleven',
      'image': 'assets/images/eleven.jpg',
      'description':
          'A young girl with psychokinetic abilities who escaped from Hawkins Lab. She forms a strong bond with Mike and his friends.',
      'abilities': ['Telekinesis', 'Remote Viewing', 'Portal Sensing'],
    },
    {
      'name': 'Mike Wheeler',
      'image': 'assets/images/mike.jpg',
      'description':
          'The leader of the group and Eleven\'s boyfriend. Mike is loyal, determined, and willing to do anything to protect his friends.',
      'abilities': ['Leadership', 'Strategy', 'Loyalty'],
    },
    {
      'name': 'Dustin Henderson',
      'image': 'assets/images/dustin.jpg',
      'description':
          'The brains of the group with a passion for science and technology. His knowledge often helps the party solve mysteries.',
      'abilities': ['Intelligence', 'Comic Relief', 'Animal Taming'],
    },
    {
      'name': 'Lucas Sinclair',
      'image': 'assets/images/lucas.jpg',
      'description':
          'The skeptic of the group who eventually becomes one of Eleven\'s strongest supporters. Expert with his wrist rocket slingshot.',
      'abilities': ['Marksmanship', 'Tactical Planning', 'Resourcefulness'],
    },
    {
      'name': 'Will Byers',
      'image': 'assets/images/will.jpg',
      'description':
          'The first victim of the Upside Down who maintains a psychic connection to the Mind Flayer after being rescued.',
      'abilities': ['Truesight', 'Upside Down Sensing', 'Drawing'],
    },
    {
      'name': 'Jim Hopper',
      'image': 'assets/images/hopper.jpg',
      'description':
          'Hawkins Chief of Police who becomes Eleven\'s adoptive father. A resourceful fighter with a troubled past.',
      'abilities': ['Combat', 'Investigation', 'Survival Skills'],
    },
    {
      'name': 'MAX MAYFIELD',
      'image': 'assets/images/max.jpg',
      'description':
          'A skateboarding newcomer to Hawkins who joins the party in Season 2.',
      'powers': 'Skateboarding, Independence, Bravery',
    },
    
    {
      'name': 'STEVE HARRINGTON',
      'image': 'assets/images/steve.jpg',
      'description':
          'Former popular high school student who becomes the "babysitter" of the group.',
      'powers': 'Nail Bat Skills, Hair Care, Charisma',
    },
  ];

  void _playClickSound() {
    audioService.playSound('audio/click.mp3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "CHARACTER PROFILES",
          style: TextStyle(fontFamily: 'BenguiatITCBold', fontSize: 20),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isUpsideDown
                  ? 'assets/images/upside_down_bg.jpg'
                  : 'assets/images/hawkins_bg.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(isUpsideDown ? 0.5 : 0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    isUpsideDown
                        ? "CREATURES AND SURVIVORS"
                        : "HAWKINS RESIDENTS",
                    style: TextStyle(
                      color:
                          isUpsideDown
                              ? Colors.teal.shade200
                              : Colors.red.shade200,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _characters.length,
                    itemBuilder: (context, index) {
                      return _buildCharacterCard(_characters[index], context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterCard(
    Map<String, dynamic> character,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        _playClickSound();
        showDialog(
          context: context,
          builder: (_) => _buildCharacterDialog(character, context),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isUpsideDown
                  ? Colors.teal.shade900.withOpacity(0.7)
                  : Colors.red.shade900.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUpsideDown ? Colors.teal.shade200 : Colors.red.shade200,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: Image.asset(character['image'], fit: BoxFit.contain),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  character['name'].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'BenguiatITCBold',
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterDialog(
    Map<String, dynamic> character,
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUpsideDown ? Colors.teal.shade900 : Colors.red.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUpsideDown ? Colors.teal.shade200 : Colors.red.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              character['name'].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'BenguiatITCBold',
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(90),
                border: Border.all(
                  color:
                      isUpsideDown ? Colors.teal.shade200 : Colors.red.shade200,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(90),
                child: Image.asset(character['image'], fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              character['description'],
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "ABILITIES",
              style: TextStyle(
                fontFamily: 'BenguiatITCBold',
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var ability in character['abilities'])
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            isUpsideDown
                                ? Colors.teal.shade100
                                : Colors.red.shade100,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ability,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isUpsideDown
                            ? Colors.teal.shade100
                            : Colors.red.shade100,
                  ),
                ),
                child: const Text(
                  "CLOSE",
                  style: TextStyle(
                    fontFamily: 'BenguiatITCBold',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
