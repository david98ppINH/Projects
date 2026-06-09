class TriviaQuestion {
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  final String? extra;

  TriviaQuestion({
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
    this.extra,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      question: json['pregunta'],
      correctAnswer: json['correcta'],
      incorrectAnswers: List<String>.from(json['incorrectas']),
      extra: json['extra'],
    );
  }
}

final List<Map<String, dynamic>> triviaQuestionsJson = [
  {
    "pregunta": "¿En qué año participó Ecuador por primera vez en una Copa Mundial de la FIFA?",
    "correcta": "2002",
    "incorrectas": ["1998", "2006", "2010"],
    "extra": "Mundial de Corea-Japón"
  },
  {
    "pregunta": "¿Quién es el máximo goleador histórico de la Selección de Ecuador en los Mundiales?",
    "correcta": "Enner Valencia",
    "incorrectas": ["Agustín Delgado", "Felipe Caicedo", "Edison Méndez"],
    "extra": "con 6 goles anotados entre 2014 y 2022"
  },
  {
    "pregunta": "¿Quién anotó el histórico primer gol de Ecuador en la historia de los Mundiales?",
    "correcta": "Agustín Delgado",
    "incorrectas": ["Álex Aguinaga", "Iván Kaviedes", "Carlos Tenorio"],
    "extra": "en 2002, ante la Selección de México"
  },
  {
    "pregunta": "¿En qué Mundial logró Ecuador su mejor participación histórica al clasificar a los Octavos de Final?",
    "correcta": "Alemania 2006",
    "incorrectas": ["Corea-Japón 2002", "Brasil 2014", "Qatar 2022"],
    "extra": "bajo la dirección técnica de Luis Fernando Suárez"
  },
  {
    "pregunta": "¿Quién es el jugador más joven en la historia de las Eliminatorias Sudamericanas de la FIFA en marcar un gol?",
    "correcta": "Kendry Páez",
    "incorrectas": ["Pelé", "Diego Maradona", "Lionel Messi"],
    "extra": "con 16 años y 161 días ante Bolivia en La Paz"
  },
  {
    "pregunta": "¿Quién es el actual director técnico que lidera a la Selección de Ecuador en el proceso mundialista?",
    "correcta": "Sebastián Beccacece",
    "incorrectas": ["Gustavo Alfaro", "Hernán Darío Gómez", "Reinaldo Rueda"],
    "extra": null
  },
  {
    "pregunta": "¿Qué defensor ecuatoriano hizo historia al convertirse en el primero de su país en levantar la UEFA Champions League?",
    "correcta": "Willian Pacho",
    "incorrectas": ["Piero Hincapié", "Pervis Estupiñán", "Félix Torres"],
    "extra": "con el Paris Saint-Germain"
  },
  {
    "pregunta": "¿En qué ciudad de Estados Unidos jugará Ecuador su primer partido del grupo el 14 de junio ante Costa de Marfil?",
    "correcta": "Philadelphia",
    "incorrectas": ["Miami", "New York", "Kansas City"],
    "extra": "en el Philadelphia Stadium"
  },
  {
    "pregunta": "¿En qué estadio de Estados Unidos disputará Ecuador su partido del grupo ante Curazao el 20 de junio?",
    "correcta": "Kansas City Stadium",
    "incorrectas": ["New York Stadium", "Houston Stadium", "Toronto Stadium"],
    "extra": "Arrowhead Stadium"
  },
  {
    "pregunta": "¿Cuál es el mediocampista defensivo que ejerce como el motor del mediocampo de Ecuador y milita en el Chelsea inglés?",
    "correcta": "Moisés Caicedo",
    "incorrectas": ["Kendry Páez", "Alan Franco", "Pedro Vite"],
    "extra": null
  },
  {
    "pregunta": "¿Qué país fue el campeón de la primera Copa Mundial de la FIFA celebrada en 1930?",
    "correcta": "Uruguay",
    "incorrectas": ["Argentina", "Brasil", "Italia"],
    "extra": null
  },
  {
    "pregunta": "¿Quién es el máximo goleador de todos los tiempos en la historia de las Copas del Mundo?",
    "correcta": "Miroslav Klose",
    "incorrectas": ["Ronaldo Nazário", "Pelé", "Lionel Messi"],
    "extra": "Alemania, con 16 goles totales"
  },
  {
    "pregunta": "¿Cuál es la única selección en el planeta que ha participado en todos los mundiales y ganado 5 títulos de la FIFA?",
    "correcta": "Brasil",
    "incorrectas": ["Alemania", "Italia", "Argentina"],
    "extra": null
  },
  {
    "pregunta": "¿Cuántos equipos compiten en la fase final de la Copa Mundial de la FIFA a partir de esta edición?",
    "correcta": "48 equipos",
    "incorrectas": ["36 equipos", "40 equipos", "64 equipos"],
    "extra": "expandido desde los 32 de la edición anterior"
  },
  {
    "pregunta": "¿Qué portero ostenta el récord de más atajadas en un solo partido mundialista en la historia moderna de la FIFA?",
    "correcta": "Tim Howard",
    "incorrectas": ["Guillermo Ochoa", "Manuel Neuer", "Gianluigi Buffon"],
    "extra": "Estados Unidos, con 16 atajadas en un solo juego en 2014"
  }
];

final List<TriviaQuestion> triviaQuestions = triviaQuestionsJson
    .map((json) => TriviaQuestion.fromJson(json))
    .toList();
