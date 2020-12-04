Project-202: Docker Swarm Deployment of Phonebook Application (Python Flask) with
- Infrastructure
    - Public Repository on Github (Codebase, Versionig System)
    - Docker Swarm as Orchestrator
        - 3 Manager-bunlardan bir tanesi de Grand Master isimli CEO olacak.
        - 2 Worker
        - üç farklı user data oluşturmamız gerekiyor.
        - bu instancelarda docker, docker compose, python3, git, aws cli yükleyeceğiz.
            '''neden aws cli yüklüyoruz?
                    çünkü burada oluşturduğumuz imageları Ecr servisine push edeceğiz.'''
    - Image Repository (AWS ECR)
    - Should be able to
        - Every EC2 is able to talk each other (EC2 Connect CLI, IAM Policy)
        - Grand Master can pull image from ECR and push image to AWS ECR
        - Mangers and Workers can pull image from AWS ECR.
- Application Deployement
    - Dockerfile
    - docker-compose.yml (Web server and Mysql)



'''bash
    neden ECR kullanıyoruz
    production ortamlarında oluşturulmuş Docker imagelar asla public/umumi herkesin ulaşabileceği yerlere koyulmuyor.
    biz de AWSnin bize sağladığı güvenli ortam olan ECRyi tercih ediyoruz.
    alternatif repositoryler için şu adrese bakabiliriz,
    https://www.g2.com/products/docker-hub/competitors/alternatives '''


NOT: Docker hub'ta kendi localimizde private ozöl bir repostiroty oluşturmamızı sağlayan imageler var.'
detaylı bilgi için : https://www.geeksforgeeks.org/creating-a-private-repository-and-push-an-image-to-that-private-repository/
detaylı bilgi için - 2 : https://www.docker.com/blog/how-to-use-your-own-registry/


güzel bir bilgi: "Docker compose tek başına bir Orchestration tool değildir. Bunun için yani orchestration için Docker Swarm
yüklememiz gerekiyor. bunu da Grand master üzerine yükleyeceğiz."

# bir docker swarm cluster kuracağımız için bu beş instance'ın birbiriyle devamlı şekiled iletişim halinde bulunması gerekiyor.
# Amazon'da servisler arası veya servis içi resourceların birbiriyle iletişime geçebilmesi IAM Policy/ler belirlememiz gerekiyor.
# bu IAM Role ile ECR'a push ve pull yapabileceğiz. ec2'lar ile birbirinden veri çekme hakkı kazanacaklar.

şunu tekrar etmek gerekirse;

    - Application yani yazılım kısmı;
        - compose,swarm, flask ve app.py dosyasının kendisi.
    -Infrastructure yani donanım kısmı;
        - gıt.docker.python yüklü makineler.


Dockerfile:(image oluşturduğumuz kısım)
"""

FROM python:alpine
COPY ./app /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 80
CMD python ./phonebook-app.py 

"""
klasik bir Dockerfile.

Docker Compose:
    - database image oluşturan ve phonebook uygulamımızı çalıştırmamızı yarayan ve Dockerfile ile oluşturduğumuz imagei
    container olarak birbirine bağlayıp ayağı kaldıracak olan dosya.

"""
version: "3.8"

services:
    database:
        image: mysql:5.7
        environment:
        # env. variables nedir arkadaş? 
        # https://10.enpedi.com/2016/03/windows-10da-kullanlan-ortam.html#gsc.tab=0
        # mesela bir program tasarlarken bilgilerin geçici kaydedileceği bir alana ihtiyaç duyuyoruz. bu farklı run-environment(işletim sistemi)
        # ve farklı bilgisayarlar için tek tek uğraşmamak için her bilgisayarda belli tanımlamalar yapılıyor. çeşitli run time env. arasında
        # ortak kullanım alanlarında terim birliği oluşturmak ortak kavramlar kullanımlamsını sağlayan sözlük, kütüphane dersek çok yanılmış olmayız.
            MYSQL_ROOT_PASSWORD: P123456p 
            # bizim mysql containera bir app bağlarken tek zorunlu olarak belirtmemiz gereken değişken root passworddür.
            # bu bilgi docker hub'ta mysql image'ın olduğu yerde görülebilir.
            MYSQL_DATABASE: phonebook_db
            MYSQL_USER: admin
            MYSQL_PASSWORD: Clarusway_1
            # yukarıdaki bilgileri tanımlamızın nedeni biz root olarak database'e bağlanmak yerine bir kullanıca belirleyip,
            # belirlediğimiz kullanıcı ile bağlanıyoruz. güvenlik kaygılarından dolayı.
            # peki mandatory olmayan bilgileri ne ifade ediyor? başlangıç databasemiz phonebook_db olsun, kullanıcı adımız admin 
            # kullanıcı şifremiz de Clarusway_1 olsun diyoruz.
        volumes:
            - db-data:/var/lib/mysql
            # biz uygulamamızı çalıştırmaya başladığımızda muhtemelen Grand master üzerinde başlayacaktır. eski uygulamalarımızda
            # databasei genelde host makinemizde bir dosyaya bağlıyorduk/mount ediyorduk. fakat bir cluster oluşturduğumuz zaman
            # databasein olduğu makinede yaşanacak bir sorun tüm databasei tehlikeye atacak ve verilerimizi kaybedebileceğimiz bir 
            # senaryo ile karşılacağız.Docker, eğer swarm yani cluster üzerinde bir volume yani database işlemi yapacaksak bize
            # data birliği oluşturmak ve olası bir negatif bir durum oluşmaması için, database'i herhangi bir yere mount etme,
            # bağlama sadece bir isim ver, gerisini bize bırak diyor. data böylece kaybolmadığı gibi databaseimiz de stabil kalacaktır.
        # configs işlemleri nedir?
        # bir database oluşturduğumuzda belli bir şablon belirlemiş ve belli verilerin girilmiş haliyle oluşturulmasını istiyorsak,
        # mysql bize diyor ki, sana bir adres göstereceğim, o göstereceğim adrese sana söylediğim uzantılarla bir dosya koyarsan 
        # bu dosyaları execute ederim. yani verdiğin bilgilere göre dosyayı oluşturur ve ayağa kaldırırım diyor.
        # istersek bunu bir volumes gibi volume ortamına bağlayabiliriz. fakat ilgili instance'ın çökme durumu ve best practice açısından
        # production ortamına uygunluğu gibi sebeplerle init.sql dosyasının öyle bir yere koyayım ki her seferinde oradan bu tabloyu çekebilsin.
        # config yapısı genel anlamıyla bu işe yarıyor.
        # init.sql tarzı yapılar database oluşurken yani sadece başlangıç için gerekli olan dosyalardır. devamlı kullanılmaz.
        # "makine çökme durumunda database sıfırdan başlamaz, kaldığı yerden devam eder."
        ############
        # https://hub.docker.com/_/mysql (ilgili kısım aşağıda.)
        # Initializing a fresh instance
        # When a container is started for the first time, a new database with the specified name will be created and 
        # initialized with the provided configuration variables. Furthermore, it will execute files with extensions 
        # .sh, .sql and .sql.gz that are found in /docker-entrypoint-initdb.d. Files will be executed in alphabetical order.
        #  You can easily populate your mysql services by mounting a SQL dump into that directory and provide custom images 
        # with contributed data. SQL files will be imported by default to the database specified by the MYSQL_DATABASE variable.
        configs:
            - source: table # istediğimiz ismi verebiliyoruz.
              target: /docker-entrypoint-initdb.d/init.sql # bizim init sql'i mount etmemizi istediği yer. dokumantasyondan.
        networks:
            - clarusnet
    app-server:
        image: ${ECR_REGISTRY}/${APPP_REPO_NAME}:latest
        # burada yeniden env.var. tanımlası yaptık. peki compose file bu değikenler için nereye bakıyor?
        # compose file'lar env.var. için ilgili dizindeki .env dosyalarına bakarlar. bu yüzden .env filelar oluşturmak önemlidir.
        # bunu cloudformation ile yapabiliriz. - ilk önce bu yolla yaptık
        # istersek jenkins ile de yapabiliriz. - daha sonra elimizle yazdık ama jenkinse de yaptırabilirdik.
        deploy:
            mode: global
            update_config:
                parallelism: 2
                delay: 5s
                order: start-first
        # deploy ile ne yapıyoruz peki?
        # burası daha çok bizim modellememiz ve aldığımız tedbirle ilgili kısım diyebiliriz.
        # global mode ile her node'a bir uygulama düşecek şekilde ayarlama yap diyoruz swarma.
        # parallelism ise kabaca şu demek; ben bu application update edersem sen hepsini birden kapatıp tekrar ayağı kaldırma,
        # onun yerine 2'şer 2'şer olarak kapatıp ayağa kaldır ve bu işlemlerin arasında da 5'şer saniye bekle.
        ###
        ekstra bilgi: "docker-compose config" komutu ile yaml halinde compose file'a bakılıp yanlışlara bakılabilir.
        ports:
            - "80:80"
        networks:
            - clarusnet
networks:
    clarusnet:
        driver: overlay

volumes:
    db-data:

configs:
    table: #verdiğimiz isim
        file: ./init.sql # bu da bizim init.sql dosyamızın yeri.
###
güzel bilgi: bir database initializing ederken container içindeki root klasörünün altında dosyayı oluşturuyor.
biz database'i taşımak istersek dosyayı buradan alıp taşıyacağız.
###

        """





