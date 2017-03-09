//TI CC2540/CC2541
#define TI_UART_SERVICE                                      0xFFF0
#define TI_UART_RX_PRIMARY_SERVICE_UUID                      0xFFE0  // for STRING RX UUID
#define TI_UART_RX_NOTIFICATION_UUID                         0xFFF4  // for STRING RX NOTIFY
#define TI_UART_RX_NOTIFICATION_READ_LEN                         20  // bytes
#define TI_UART_TX_PRIMARY_SERVICE_UUID                      0xFFF0  // for STRING TX UUID
#define TI_UART_TX_SECOND_UUID                               0xFFF5
#define TI_UART_TX_WRITE_LEN                                     20  // bytes
//BLE to Serial
//微程式
#define WT_SPP_SERVICE_UUID                                 0xFFF0  // for STRING RX UUID
#define WT_SPP_NOTIFY_UUID                                  0xFFF4  // for STRING RX NOTIFY
#define WT_SPP_DATA_UUID                                    0xFFF5
#define WT_SPP_DATA_LEN                                     20
//久邦
#define JB_UART_RX_PRIMARY_SERVICE_UUID                      0xFFE0  // for STRING RX UUID
#define JB_UART_RX_NOTIFICATION_UUID                         0xFFE2  // for STRING RX NOTIFY
#define JB_UART_RX_NOTIFICATION_READ_LEN                         20  // bytes
#define JB_UART_TX_PRIMARY_SERVICE_UUID                      0xFFF0  // for STRING TX UUID
#define JB_UART_TX_SECOND_UUID                               0xFFF5
#define JB_UART_TX_WRITE_LEN                                     20  // bytes
//新嘩
#define SERIAL_UART_TX_SERVICE_UUID                         0xFFF0
#define SERIAL_UART_TX_CHARACTERISTIC                       0xFFF1
//#define DYCOREBLUETOOTH_DEBUG
#define BLE_RX_BUFFER_LEN JB_UART_RX_NOTIFICATION_READ_LEN
