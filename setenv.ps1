#####################################################################
#                                                                   #
#   Tridion Content Delivery environment variables script           #
#                                                                   #
#   some values are dependent on TARGET_FOLDER & HOST_IP            #
#                                                                   #
#####################################################################

$delivery_vars["./logs"] = $delivery_vars["TARGET_FOLDER"] + "log"

# Content
$delivery_vars["CONTENT_DEFAULT_SERVER_NAME"] = "mssqlserver.hostname"
$delivery_vars["CONTENT_DEFAULT_PORT_NUMBER"] = "1433"
$delivery_vars["CONTENT_DEFAULT_DATABASE_NAME"] = "database.name"
$delivery_vars["CONTENT_DEFAULT_USER"] = "user.name"
$delivery_vars["CONTENT_DEFAULT_PASSWORD"] = "user.password"

# Preview
$delivery_vars["PREVIEW_DEFAULT_SERVER_NAME"] = "mssqlserver.hostname"
$delivery_vars["PREVIEW_DEFAULT_PORT_NUMBER"] = "1433"
$delivery_vars["PREVIEW_DEFAULT_DATABASE_NAME"] = "database.name"
$delivery_vars["PREVIEW_DEFAULT_USER"] = "user.name"
$delivery_vars["PREVIEW_DEFAULT_PASSWORD"] = "user.password"

# UGC
$delivery_vars["UGC_DEFAULT_SERVER_NAME"] = "mssqlserver.hostname"
$delivery_vars["UGC_DEFAULT_PORT_NUMBER"] = "1433"
$delivery_vars["UGC_DEFAULT_DATABASE_NAME"] = "database.name"
$delivery_vars["UGC_DEFAULT_USER"] = "user.name"
$delivery_vars["UGC_DEFAULT_PASSWORD"] = "user.password"

$delivery_vars["DEFAULT_FILE"] = $delivery_vars["TARGET_FOLDER"] + "service_folder\service\tmp"
$delivery_vars["DEFAULT_DATA_FILE"] = $delivery_vars["TARGET_FOLDER"] + "all\service_folder\tmp\data"

# Deployer Endpoint and Deployer Engine
$delivery_vars["DEPLOYER_STATE_DEFAULT_SERVER_NAME"] = "mssqlserver.hostname"
$delivery_vars["DEPLOYER_STATE_DEFAULT_PORT_NUMBER"] = "1433"
$delivery_vars["DEPLOYER_STATE_DEFAULT_DATABASE_NAME"] = "database.name"
$delivery_vars["DEPLOYER_STATE_DEFAULT_USER"] = "user.name"
$delivery_vars["DEPLOYER_STATE_DEFAULT_PASSWORD"] = "user.password"

$delivery_vars["QUEUE_PATH"] = $delivery_vars["TARGET_FOLDER"] + "service_folder\queue\incoming"

$delivery_vars["BINARY_PATH"] = $delivery_vars["TARGET_FOLDER"] + "service_folder\binary"
