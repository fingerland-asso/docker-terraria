############################### change if needed ###############################
CONTAINER=terrariaserver
VOLUME=/data/dockers/${CONTAINER}
IMAGE=fingerland/${CONTAINER}
OPTIONS=-v ${VOLUME}:/server
################################ computed data #################################
SERVICE_ENV_FILE=${PWD}/${CONTAINER}.env
SERVICE_FILE=${PWD}/${CONTAINER}.service
################################################################################

help:
	@echo "Fingerland Terraria  (docker builder)"

build:
	@docker build -t ${IMAGE} .

volume:
	@mkdir -p ${VOLUME}
	@chown -R 1000:1000 ${VOLUME}

stop:
	@docker kill ${CONTAINER} || echo ""
	@docker rm ${CONTAINER} || echo ""

run: volume stop
	@docker run --restart=always -d -ti ${OPTIONS} --name=${CONTAINER} ${IMAGE}
	@docker logs -f ${CONTAINER}

systemd-service:
	@cp service.sample ${SERVICE_FILE}
	@sed -i -e "s;ExecStartPre=-/usr/bin/docker pull.*$$;ExecStartPre=-/usr/bin/docker pull ${IMAGE};"  ${SERVICE_FILE}
	@sed -i -e "s;ExecStartPre=-/usr/bin/docker rm.*$$;ExecStartPre=-/usr/bin/docker rm ${CONTAINER};"  ${SERVICE_FILE}
	@sed -i -e "s;ExecStartPre=-/usr/bin/docker kill.*$$;ExecStartPre=-/usr/bin/docker kill ${CONTAINER};"  ${SERVICE_FILE}
	@sed -i -e "s;ExecStart=.*$$;ExecStart=/usr/bin/docker run -i --name=${CONTAINER} ${OPTIONS} ${IMAGE};"  ${SERVICE_FILE}
	@sed -i -e "s;ExecStop=.*$$;ExecStop=/usr/bin/docker stop ${CONTAINER};"  ${SERVICE_FILE}
	@systemctl enable ${SERVICE_FILE}
	@systemctl daemon-reload

install: build volume systemd-service
	@sudo systemctl start ${CONTAINER}.service
