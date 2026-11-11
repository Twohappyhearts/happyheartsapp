// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get done => 'Listo';

  @override
  String get close => 'Cerrar';

  @override
  String get back => 'Atrás';

  @override
  String get view => 'Ver';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtelo de nuevo.';

  @override
  String get errorConnection =>
      'Algo salió mal. Revise su conexión e inténtelo de nuevo.';

  @override
  String get errorServerUnreachable =>
      'No se pudo conectar con el servidor. Revise su conexión e inténtelo de nuevo.';

  @override
  String get couldNotOpenLink => 'No se pudo abrir este enlace.';

  @override
  String get requestSent =>
      'Solicitud enviada. Un miembro del equipo se comunicará con usted.';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get statusAvailable => 'Disponible';

  @override
  String get statusNotStarted => 'Sin empezar';

  @override
  String get dateToday => 'Hoy';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String dateTodayAt(String time) {
    return 'Hoy, $time';
  }

  @override
  String dateYesterdayAt(String time) {
    return 'Ayer, $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date, $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String timeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String timeHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String linkSemantic(String text) {
    return 'Enlace: $text';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languagePhone => 'Idioma del teléfono';

  @override
  String languagePhoneDetail(String language) {
    return 'Igual que su teléfono ($language)';
  }

  @override
  String get languagePickerTitle => 'Elija un idioma';

  @override
  String languageButtonSemantic(String language) {
    return 'Idioma: $language. Toque para cambiarlo.';
  }

  @override
  String get authTagline => 'Su compañero personal de educación para la salud';

  @override
  String get authTabSignIn => 'Iniciar sesión';

  @override
  String get authTabCreateAccount => 'Crear cuenta';

  @override
  String get signInWelcome => 'Bienvenido de nuevo 👋';

  @override
  String get signInSubtitle =>
      'Inicie sesión para continuar con su aprendizaje sobre la salud';

  @override
  String get fieldEmail => 'Correo electrónico';

  @override
  String get fieldEmailHint => 'Escriba su correo electrónico';

  @override
  String get validationEmailRequired => 'Escriba su correo electrónico';

  @override
  String get validationEmailInvalid => 'Escriba un correo electrónico válido';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get fieldPasswordHint => 'Escriba su contraseña';

  @override
  String get validationPasswordRequired => 'Escriba su contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get signInForgot => '¿Olvidó su contraseña?';

  @override
  String get createTitle => 'Cree su cuenta';

  @override
  String get createSubtitle => 'Comience hoy a aprender sobre su salud';

  @override
  String get fieldFullName => 'Nombre completo';

  @override
  String get fieldFullNameHint => 'Escriba su nombre completo';

  @override
  String get validationNameRequired => 'Escriba su nombre';

  @override
  String get fieldUsername => 'Nombre de usuario';

  @override
  String get fieldUsernameHint =>
      'El nombre de usuario que le dio el equipo del estudio';

  @override
  String get fieldUsernameHelper =>
      'Use el nombre de usuario que le dio el equipo del estudio. Conecta sus encuestas con su cuenta y no se puede cambiar después.';

  @override
  String get validationUsernameRequired => 'Escriba su nombre de usuario';

  @override
  String get validationUsernameFormat =>
      'Use de 3 a 20 letras o números (sin espacios ni símbolos)';

  @override
  String get fieldPhone => 'Número de teléfono';

  @override
  String get fieldPhoneHint => 'p. ej., (949) 555-0100';

  @override
  String get validationPhoneRequired => 'Escriba su número de teléfono';

  @override
  String get validationPhoneInvalid => 'Escriba un número de teléfono válido';

  @override
  String get fieldCreatePasswordHint => 'Cree una contraseña';

  @override
  String get validationNewPasswordRequired => 'Escriba una contraseña';

  @override
  String get validationPasswordMin8 =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get fieldConfirmPassword => 'Confirmar contraseña';

  @override
  String get fieldConfirmPasswordHint => 'Escriba su contraseña otra vez';

  @override
  String get validationConfirmRequired => 'Confirme su contraseña';

  @override
  String get validationPasswordsMismatch => 'Las contraseñas no coinciden';

  @override
  String get legalTerms => 'Términos de uso';

  @override
  String get legalPrivacy => 'Política de privacidad';

  @override
  String createAgree(String terms, String privacy) {
    return 'Acepto los $terms y la $privacy';
  }

  @override
  String get createAgreeRequired =>
      'Acepte los Términos de uso y la Política de privacidad';

  @override
  String get authErrorCredentials =>
      'Correo electrónico o contraseña incorrectos.';

  @override
  String get authErrorUsernameRejected =>
      'Ese nombre de usuario ya está en uso o no está permitido. Elija otro.';

  @override
  String get authErrorUsernameTaken =>
      'Ese nombre de usuario ya está en uso. Use el nombre de usuario que le dio el equipo del estudio o comuníquese con el equipo de atención si ya está registrado.';

  @override
  String get authErrorDisabled =>
      'Esta cuenta está desactivada. Comuníquese con su equipo de atención.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirme su correo electrónico antes de iniciar sesión.';

  @override
  String get authErrorEmailExists =>
      'Ya existe una cuenta con este correo electrónico. Intente iniciar sesión.';

  @override
  String get authErrorRateLimited =>
      'Demasiados intentos. Espere un minuto e inténtelo de nuevo.';

  @override
  String get authErrorPassword => 'Elija otra contraseña.';

  @override
  String get checkEmailTitle => 'Revise su correo electrónico';

  @override
  String checkEmailBody(String email) {
    return 'Enviamos un enlace de confirmación a\n$email\nÁbralo en este dispositivo para terminar de crear su cuenta.';
  }

  @override
  String get checkEmailResent => 'Volvimos a enviar el correo de confirmación.';

  @override
  String get checkEmailResend => 'Reenviar correo de confirmación';

  @override
  String get backToSignIn => 'Volver a iniciar sesión';

  @override
  String get forgotTitle => 'Restablezca su contraseña';

  @override
  String get forgotIntro =>
      'Escriba su correo electrónico y le enviaremos un enlace para restablecerla.';

  @override
  String forgotSent(String email) {
    return 'Si existe una cuenta para $email, le enviamos un enlace para restablecer la contraseña. Ábralo en este dispositivo.';
  }

  @override
  String get forgotSend => 'Enviar enlace';

  @override
  String get resetTitle => 'Elija una contraseña nueva';

  @override
  String get passwordMinShort => 'Use al menos 8 caracteres.';

  @override
  String get fieldNewPassword => 'Contraseña nueva';

  @override
  String get fieldConfirmNewPassword => 'Confirmar contraseña nueva';

  @override
  String get resetButton => 'Actualizar contraseña';

  @override
  String get gateTitle => 'Cree una contraseña nueva';

  @override
  String get gateBody =>
      'Su equipo de atención creó esta cuenta con una contraseña temporal. Elija su propia contraseña para continuar.';

  @override
  String get gateRule =>
      'Al menos 8 caracteres, con una letra mayúscula, una minúscula y un número.';

  @override
  String get gateErrorMix =>
      'Incluya una letra mayúscula, una minúscula y un número.';

  @override
  String get gateSuccess => 'Contraseña actualizada. ¡Bienvenido!';

  @override
  String get gateErrorSame => 'Elija una contraseña distinta de la temporal.';

  @override
  String get gateErrorFailed =>
      'No se pudo actualizar su contraseña. Revise su conexión.';

  @override
  String get gateSave => 'Guardar contraseña';

  @override
  String get menuOpen => 'Abrir menú';

  @override
  String get menuAssessments => 'Evaluaciones integrales';

  @override
  String get menuAssessmentsSubtitle =>
      'Cuestionarios de su equipo de atención';

  @override
  String get menuAssistance => 'Necesito ayuda';

  @override
  String get menuAssistanceSubtitle => 'Pida ayuda a su equipo de atención';

  @override
  String get menuMyRequests => 'Mis solicitudes de ayuda';

  @override
  String get menuMyRequestsSubtitle => 'Vea el estado de lo que envió';

  @override
  String get menuEmergency => 'En caso de emergencia, llame al 911.';

  @override
  String get navEducation => 'Educación';

  @override
  String get navResources => 'Recursos';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Perfil';

  @override
  String get crashTitle => 'Algo salió mal';

  @override
  String get crashBody =>
      'Reinicie la aplicación. Si sigue pasando, comuníquese con el equipo de investigación.';

  @override
  String get homeGoodMorning => 'Buenos días';

  @override
  String get homeGoodAfternoon => 'Buenas tardes';

  @override
  String get homeGoodEvening => 'Buenas noches';

  @override
  String get homeHi => 'Hola 👋';

  @override
  String homeHiName(String name) {
    return 'Hola, $name 👋';
  }

  @override
  String get homeTitle => 'Su centro de\neducación para la salud';

  @override
  String get homeSearchHint => 'Buscar lecciones o temas...';

  @override
  String get homeCategoryAll => 'Todas';

  @override
  String get homeNoLessons =>
      'Todavía no hay lecciones disponibles. Vuelva pronto.';

  @override
  String get homeNoMatches => 'Ninguna lección coincide con su búsqueda.';

  @override
  String get progressCardTitle => 'Su progreso';

  @override
  String progressCardLessons(int completed, int total) {
    return '$completed / $total lecciones';
  }

  @override
  String get progressCardStart => '¡Comencemos!';

  @override
  String progressCardGreat(int percent) {
    return '$percent% completado: ¡va muy bien!';
  }

  @override
  String progressCardKeepGoing(int percent) {
    return '$percent% completado: ¡siga así!';
  }

  @override
  String get progressCardDone => '100% completado: ¡excelente trabajo!';

  @override
  String get lessonHeader => 'Lección';

  @override
  String get lessonNoLessonsShort => 'Todavía no hay lecciones disponibles.';

  @override
  String get lessonNoneSelected => 'No se seleccionó ninguna lección.';

  @override
  String get lessonMarked => 'Lección marcada como completada. ¡Buen trabajo!';

  @override
  String get lessonCompletedTitle => 'Lección completada';

  @override
  String get lessonFinishPrompt => '¿Terminó esta lección?';

  @override
  String get lessonCompletedBody =>
      '¡Buen trabajo! Puede volver a repasarla cuando quiera.';

  @override
  String get lessonFinishBody =>
      'Márquela como completada para llevar el control de su progreso.';

  @override
  String get lessonMarkButton => 'Marcar como completada';

  @override
  String lessonSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secciones',
      one: '1 sección',
    );
    return '$_temp0';
  }

  @override
  String get refTitle => 'Referencias';

  @override
  String get refLessonVideo => 'Video de la lección';

  @override
  String get refLessonAudio => 'Audio de la lección';

  @override
  String get scriptTitle => 'Notas de la lección';

  @override
  String get scriptReadMore => 'Leer más';

  @override
  String get scriptShowLess => 'Mostrar menos';

  @override
  String get infoTitle => 'Infografía';

  @override
  String get infoCardTitle => 'Infografía de la lección';

  @override
  String infoCardSubtitle(String title) {
    return 'Resumen visual de $title';
  }

  @override
  String infoSemantic(String title) {
    return 'Infografía de $title';
  }

  @override
  String get infoTapHint =>
      'Toque la imagen para verla en pantalla completa y ampliarla';

  @override
  String get imageOpenFullscreen => 'Ver en pantalla completa';

  @override
  String get imageLoadFailed => 'No se pudo cargar la imagen.';

  @override
  String get imageCloseFullscreen => 'Cerrar pantalla completa';

  @override
  String get imageZoomHint => 'Pellizque o toque dos veces para ampliar';

  @override
  String get videoTitle => 'Lección en video';

  @override
  String get videoPlaying => 'Reproduciendo video';

  @override
  String get videoTapToPlay => 'Toque para ver el video';

  @override
  String get videoYouTube => 'Video de YouTube';

  @override
  String get audioTitle => 'Lección en audio';

  @override
  String get audioOpen => 'Abrir audio';

  @override
  String get audioListen => 'Escuche esta lección';

  @override
  String get kahootTitle => 'Juego de conocimientos';

  @override
  String get kahootMarked =>
      '¡Buen trabajo! Cuestionario marcado como terminado.';

  @override
  String get kahootCopied => 'Nombre de usuario copiado.';

  @override
  String get kahootCopyTooltip => 'Copiar nombre de usuario';

  @override
  String get kahootUsernameLabel => 'Su nombre de usuario de Kahoot';

  @override
  String get kahootUsernameHint =>
      'Use este nombre de usuario cuando el juego de Kahoot le pida un apodo';

  @override
  String get kahootIntro =>
      'Ponga a prueba lo que aprendió con un juego interactivo de Kahoot!';

  @override
  String get kahootBadgeTime => '⏱ ~5 min';

  @override
  String get kahootBadgeInteractive => '✨ Interactivo';

  @override
  String get kahootBadgeFun => '🎉 ¡Divertido!';

  @override
  String get kahootStart => 'Empezar el juego de Kahoot!';

  @override
  String get kahootEmbedHint =>
      'El juego se abre abajo cuando toca el botón de arriba';

  @override
  String get kahootFinished => 'Cuestionario terminado';

  @override
  String get kahootIFinished => 'Terminé el cuestionario';

  @override
  String get chatAiTitle => 'Asistente de IA';

  @override
  String get chatAiSubtitle => 'Respuestas automáticas, 24/7';

  @override
  String get chatTeamTitle => 'Equipo de investigación';

  @override
  String get chatTeamSubtitle => 'Estudio Happy Hearts';

  @override
  String get chatTabTeam => 'Equipo de atención';

  @override
  String get chatSignInAi => 'Inicie sesión para usar el asistente de IA.';

  @override
  String get chatSignIn => 'Inicie sesión para usar el chat.';

  @override
  String get chatNeedHelp => '¿Necesita ayuda con algo?';

  @override
  String get chatViewRequests => 'Ver mis solicitudes';

  @override
  String get chatEmptyTitle => 'Inicie una conversación';

  @override
  String get chatEmptyBody =>
      'Envíe un mensaje al equipo de investigación de Happy Hearts. Estamos aquí para ayudarle con cualquier pregunta sobre su estudio.';

  @override
  String get chatNotSent => 'No enviado';

  @override
  String get chatDelete => 'Eliminar';

  @override
  String get chatSending => 'Enviando…';

  @override
  String get chatInputHint => 'Escriba al equipo de investigación...';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatErrorWrongAccount =>
      'Esta cuenta no puede usar el chat de pacientes. Inicie sesión con una cuenta de paciente.';

  @override
  String get chatErrorOpen =>
      'No se pudo abrir su conversación. Inténtelo de nuevo.';

  @override
  String get chatErrorLoad =>
      'No se pudieron cargar los mensajes. Revise su conexión e inténtelo de nuevo.';

  @override
  String get chatErrorKept =>
      'No se pudo conectar con el servidor. Su mensaje se guardó. Toque Reintentar.';

  @override
  String get chatErrorNoPermission =>
      'No tiene permiso para enviar mensajes en esta conversación.';

  @override
  String get chatErrorLength =>
      'Los mensajes deben tener entre 1 y 4000 caracteres.';

  @override
  String get chatErrorNotSent => 'Mensaje no enviado. Inténtelo de nuevo.';

  @override
  String get chatErrorGeneric => 'Algo salió mal al cargar su conversación.';

  @override
  String get aiErrorConnection =>
      'No se pudo cargar el asistente de IA. Revise su conexión.';

  @override
  String get aiErrorUnavailable =>
      'El asistente de IA no está disponible en este momento.';

  @override
  String get aiErrorStart => 'No se pudo iniciar el asistente de IA.';

  @override
  String get aiErrorTimeout =>
      'El asistente de IA está tardando demasiado en cargar.';

  @override
  String get aiWebOnly =>
      'El asistente de IA está disponible en la aplicación HappyHearts para iOS y Android.';

  @override
  String get assistMyRequests => 'Mis solicitudes';

  @override
  String get assistIntro =>
      'Cuéntele al equipo de investigación con qué necesita ayuda. Un miembro del equipo le responderá, normalmente por mensaje en el chat del Equipo de atención.';

  @override
  String get assistEmergency =>
      'Esto no se revisa las 24 horas. Si es una emergencia, llame al 911.';

  @override
  String get assistHint =>
      'Por ejemplo: \"Tengo una pregunta sobre mi medicamento\" o \"El video de la Sesión 3 no se reproduce.\"';

  @override
  String get assistSend => 'Enviar solicitud';

  @override
  String get assistErrorEmpty => 'Describa con qué necesita ayuda.';

  @override
  String assistErrorTooLong(int max) {
    return 'Su mensaje debe tener menos de $max caracteres.';
  }

  @override
  String get assistErrorOffline =>
      'No se pudo conectar con el servidor. Su mensaje se guardó; inténtelo de nuevo.';

  @override
  String get assistErrorLoad =>
      'No se pudieron cargar sus solicitudes. Revise su conexión e inténtelo de nuevo.';

  @override
  String get assistErrorNotParticipant =>
      'Solo las cuentas de participantes pueden enviar solicitudes de ayuda.';

  @override
  String assistErrorLength(int max) {
    return 'Escriba un mensaje de entre 1 y $max caracteres.';
  }

  @override
  String get assistErrorRateLimited =>
      'Envió varias solicitudes hace poco. El equipo le responderá pronto. Si es urgente, llame a su equipo de atención. En una emergencia, llame al 911.';

  @override
  String get assistErrorNotSent =>
      'Su solicitud no se envió. Su mensaje se guardó; inténtelo de nuevo.';

  @override
  String get requestsTitle => 'Mis solicitudes de ayuda';

  @override
  String get requestsNew => 'Nueva solicitud';

  @override
  String get requestsEmptyTitle => 'Aún no hay solicitudes';

  @override
  String get requestsEmptyBody =>
      'Cuando necesite ayuda del equipo de investigación, envíe una solicitud y podrá ver su estado aquí.';

  @override
  String get requestStatusSent => 'Enviada';

  @override
  String get requestStatusSeen => 'Vista por el equipo';

  @override
  String get requestStatusResolved => 'Resuelta';

  @override
  String get requestWaiting =>
      'Esperando a que un miembro del equipo la revise.';

  @override
  String get requestFollowing =>
      'Un miembro del equipo le está dando seguimiento.';

  @override
  String requestFollowingSince(String time) {
    return 'Un miembro del equipo le está dando seguimiento ($time).';
  }

  @override
  String get requestResolved => 'Marcada como resuelta.';

  @override
  String requestResolvedSince(String time) {
    return 'Marcada como resuelta ($time).';
  }

  @override
  String get assessSubtitleSurvey => 'Cuestionarios de su equipo de atención.';

  @override
  String get assessSubtitleResources =>
      'Lleve el control de su salud mental y física con estas herramientas de evaluación validadas.';

  @override
  String get assessEmptySurvey =>
      'Por ahora no hay evaluaciones integrales. Su equipo de atención las agregará aquí.';

  @override
  String get assessEmptyResources =>
      'Por ahora no hay recursos. Su equipo de atención los agregará aquí.';

  @override
  String get assessUsernameError =>
      'No se pudo cargar su nombre de usuario. Inténtelo de nuevo.';

  @override
  String assessLastCompleted(String date) {
    return 'Completado por última vez: $date';
  }

  @override
  String get assessStart => 'Empezar evaluación';

  @override
  String get surveyErrorLoad =>
      'No se pudieron cargar las encuestas. Revise su conexión e inténtelo de nuevo.';

  @override
  String get surveyRecordFailed =>
      'Sus respuestas se enviaron, pero la aplicación no pudo marcar la encuesta como completada.';

  @override
  String get surveyThanks => '¡Gracias!';

  @override
  String get surveyThanksBody =>
      'Sus respuestas se enviaron. Puede ver esta encuesta en su calendario de Progreso.';

  @override
  String get surveyLoading => 'Cargando encuesta...';

  @override
  String get surveyLoadFailedTitle => 'No se pudo cargar la encuesta';

  @override
  String get surveyLoadFailedBody =>
      'Revise su conexión a internet e inténtelo de nuevo.';

  @override
  String get progressSubtitle => 'Siga su aprendizaje y celebre sus logros.';

  @override
  String get progressCalendar => 'Calendario de actividad';

  @override
  String get progressBreakdown => 'Lecciones';

  @override
  String activityCompleted(String title) {
    return 'Completado: $title';
  }

  @override
  String activityQuizFinished(String title) {
    return 'Cuestionario terminado: $title';
  }

  @override
  String activitySurveyFallback(String code) {
    return 'Encuesta ($code)';
  }

  @override
  String get calPrevMonth => 'Mes anterior';

  @override
  String get calNextMonth => 'Mes siguiente';

  @override
  String get legendLesson => 'Lección';

  @override
  String get legendQuiz => 'Cuestionario';

  @override
  String get legendSurvey => 'Encuesta';

  @override
  String get calLessonDone => 'lección completada';

  @override
  String get calQuizDone => 'cuestionario terminado';

  @override
  String get calSurveyDone => 'encuesta completada';

  @override
  String get activityRecent => 'Actividad reciente';

  @override
  String activityOnDay(String date) {
    return 'Actividad del $date';
  }

  @override
  String get activityShowAll => 'Ver todo';

  @override
  String get activityEmpty =>
      'Complete una lección, un cuestionario o una encuesta y aparecerá aquí.';

  @override
  String get activityEmptyDay => 'No completó nada este día.';

  @override
  String get overallTitle => 'Avance general';

  @override
  String overallCount(int completed, int total) {
    return '$completed de $total lecciones';
  }

  @override
  String get overallAllDone => '🎉 ¡Completó todas las lecciones!';

  @override
  String get overallKeepGoing => '¡Siga así, está avanzando muy bien!';

  @override
  String get overallStart => 'Empiece su primera lección para comenzar.';

  @override
  String get statTimeSpent => 'Tiempo dedicado';

  @override
  String timeSpentSuffix(String time) {
    return '$time dedicados';
  }

  @override
  String get profileSignOutConfirm => '¿Seguro que quiere cerrar sesión?';

  @override
  String profileResetSent(String email) {
    return 'Enlace para restablecer la contraseña enviado a $email';
  }

  @override
  String get profileAccount => 'Cuenta';

  @override
  String get profileChangePassword =>
      'Cambiar contraseña (enviar correo para restablecerla)';

  @override
  String get profilePreferences => 'Preferencias';

  @override
  String get profileAbout => 'Información';

  @override
  String get profileVersion => 'Versión de la aplicación';

  @override
  String get profileNotAvailable => 'Su perfil no está disponible.';

  @override
  String get profileEditName => 'Editar nombre';

  @override
  String get profileLearningSummary => 'Resumen de aprendizaje';

  @override
  String get profileStatComplete => 'Completado';

  @override
  String get profileProgressFailed =>
      'No se pudo cargar su progreso. Toque para reintentar.';

  @override
  String get profileErrorSignIn => 'Inicie sesión.';

  @override
  String get profileErrorSessionChanged =>
      'La sesión cambió. Inténtelo de nuevo.';

  @override
  String get profileErrorMissing =>
      'No se encontró su perfil. Deslice hacia abajo para reintentar; si sigue pasando, comuníquese con el equipo de investigación.';

  @override
  String get profileErrorPermission => 'No tiene permiso para ver este perfil.';

  @override
  String get profileErrorLoad =>
      'No se pudo cargar su perfil. Revise su conexión e inténtelo de nuevo.';

  @override
  String get profileErrorNameEmpty => 'El nombre no puede estar vacío.';

  @override
  String get profileErrorSaveName =>
      'No se pudo guardar su nombre. Revise su conexión e inténtelo de nuevo.';

  @override
  String get contentErrorLessons =>
      'No se pudieron cargar las lecciones. Revise su conexión e inténtelo de nuevo.';

  @override
  String get contentErrorProgress =>
      'No se pudo cargar su progreso. Revise su conexión e inténtelo de nuevo.';

  @override
  String get materialsTitle => 'Materiales';

  @override
  String get materialsPdf => 'Documento PDF';

  @override
  String materialsPdfSize(String size) {
    return 'PDF · $size';
  }

  @override
  String fileSizeMb(String size) {
    return '$size MB';
  }

  @override
  String fileSizeKb(String size) {
    return '$size KB';
  }

  @override
  String materialsOpenImage(String name) {
    return 'Abrir imagen: $name';
  }

  @override
  String materialsOpenPdf(String name) {
    return 'Abrir PDF: $name';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get msgLangTitle => 'Revise el idioma de su mensaje';

  @override
  String msgLangBody(String languages) {
    return 'El equipo de investigación solo lee estos idiomas: $languages. Es posible que no entiendan su mensaje.';
  }

  @override
  String get msgLangSendAnyway => 'Enviar de todos modos';

  @override
  String get msgLangEdit => 'Editar mensaje';
}
