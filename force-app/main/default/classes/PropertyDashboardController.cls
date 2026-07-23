public with sharing class PropertyDashboardController {
  @AuraEnabled(cacheable=true)
  public static DashboardData getDashboardData(Id propertyId) {
    List<Property__c> lstProperties = PropertySelector.getPropertyById(
      propertyId
    );

    if (lstProperties.isEmpty()) {
      throw AuraExceptionUtil.create(System.Label.Property_Not_Found);
    }
    DashboardData data = new DashboardData();
    Date startOfMonth = Date.today().toStartOfMonth();
    Date startOfNextMonth = startOfMonth.addMonths(1);
    Property__c property = lstProperties[0];
    data.totalRooms = property.Room_Count__c;

    Map<String, Integer> countsByStatus = RoomSelector.getRoomCountsByStatusForProperty(
      propertyId
    );

    data.occupiedRooms = countsByStatus.containsKey('Occupied')
      ? countsByStatus.get('Occupied')
      : 0;
    data.monthlyRevenue = ReservationSelector.getMonthlyRevenueForProperty(
      propertyId,
      startOfMonth,
      startOfNextMonth
    );
    data.pendingTasksCount = MaintenanceTaskSelector.getPendingCountForProperty(
      propertyId
    );

    return data;
  }

  public class DashboardData {
    @AuraEnabled
    public Decimal totalRooms;
    @AuraEnabled
    public Integer occupiedRooms;
    @AuraEnabled
    public Decimal monthlyRevenue;
    @AuraEnabled
    public Integer pendingTasksCount;
  }
}
