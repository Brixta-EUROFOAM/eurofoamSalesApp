class TechnicalFlags {
  final bool attendance;
  final bool masonManagement;
  //mason management stuff
  final bool approveBagLift;
  final bool approveKyc;
  final bool approveRewards;
  final bool myMasons;
  final bool technicalOps;
  final bool createTvr;
  final bool registerSite;
  final bool addDealerSubDealer;
  final bool logTsoMeeting;
  //pantydropping navigation
  final bool dashboard;
  final bool visits;
  final bool journey;
  final bool profile;
  //pjp screen flags
  final bool createPjp;
  final bool pjpjourney;
  final bool bulkpjp;
  //journey screen nigga
  final bool journeyMap;
  final bool journeyTracking;
  final bool journeyStartStop;
  final bool journeyNavigation;
  final bool journeyNotifications;

  //newfeature
  final bool unplannedJourney;

  final bool showDbViewer;

  const TechnicalFlags({
    required this.attendance,
    required this.masonManagement,
    required this.approveBagLift,
    required this.approveKyc,
    required this.approveRewards,
    required this.myMasons,
    required this.technicalOps,
    required this.createTvr,
    required this.registerSite,
    required this.addDealerSubDealer,
    required this.logTsoMeeting,
    required this.dashboard,
    required this.visits,
    required this.journey,
    required this.profile,
    required this.createPjp,
    required this.bulkpjp,
    required this.pjpjourney,
    required this.journeyMap,
    required this.journeyTracking,
    required this.journeyStartStop,
    required this.journeyNavigation,
    required this.journeyNotifications,
    required this.unplannedJourney,
    required this.showDbViewer,
  });

  static const TechnicalFlags dev = TechnicalFlags(
    attendance: true,
    masonManagement: true,
    technicalOps: true,
    approveBagLift: true,
    approveKyc: true,
    approveRewards: true,
    myMasons: true,
    createTvr: true,
    registerSite: true,
    addDealerSubDealer: true,
    logTsoMeeting: true,
    //nav bar stuff
    dashboard: true,
    journey: true,
    visits: true,
    profile: true,
    //pjp
    createPjp: true,
    bulkpjp: true,
    pjpjourney: true,
    //journey
    journeyMap: true,
    journeyNavigation: true,
    journeyStartStop: true,
    journeyTracking: true,
    journeyNotifications: true,
    //new feature
    unplannedJourney: true,

    showDbViewer: false,
  );
}
