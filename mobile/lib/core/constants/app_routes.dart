class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const profile = '/profile';
  static const exercises = '/exercises';
  static const workouts = '/workouts';
  static const progress = '/progress';
  static const analytics = '/analytics';
  static const aiAssistant = '/ai-assistant';
  static const payments = '/payments';
  static const premium = '/premium';
  static const checkout = '/premium/checkout';
  static const paymentSuccess = '/payment-success';
  static const trainerDashboard = '/trainer';
  static const trainerPrograms = '/trainer/programs';
  static const trainerClients = '/trainer/clients';
  static const adminDashboard = '/admin';
  static const adminUsers = '/admin/users';
  static const adminExercises = '/admin/exercises';
  static const adminPayments = '/admin/payments';

  static const authRoutes = <String>{
    login,
    register,
    forgotPassword,
  };

  static const trainerRoutes = <String>{
    trainerDashboard,
    trainerPrograms,
    trainerClients,
  };

  static const adminRoutes = <String>{
    adminDashboard,
    adminUsers,
    adminExercises,
    adminPayments,
  };
}
