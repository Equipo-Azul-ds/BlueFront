import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart' as staggered;
import 'package:provider/provider.dart';
import 'package:trivvy/presentation/blocs/kahoot_editor_bloc.dart';
import '../../core/constants/colors.dart';
import '../../domain/entities/kahoot.dart';
import '../widgets/kahoot_card.dart';
import '../widgets/staggered_grid.dart';

class DashboardPage extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    final kahootBloc = Provider.of<KahootEditorBloc>(context);

    //Datos simualdos que posteriormente se reemplazaran con la api
      final recentKahoots = [
        Kahoot(id: '1', title: 'Arquitectura Hexagonal', visibility: 'publico', status: 'publico', themes: [], authorId: 'Massiel', createdAt: DateTime.now()),
        Kahoot(id: '2', title: 'Desarrollo de software', visibility: 'publico', status: 'publico', themes: [], authorId: 'Jose', createdAt: DateTime.now()),
      ];

      final recommendedKahoots = [
        Kahoot(id: '3', title: 'Casos de uso - POO', visibility: 'publico', status: 'publico', themes: [], authorId: 'Massiel', createdAt: DateTime.now()),
        Kahoot(id: '4', title: 'hOLA ESTO ES UNA PRUEBA', visibility: 'publico', status: 'publico', themes: [], authorId: 'Jose', createdAt: DateTime.now()),
      ];

      return Scaffold(
        backgroundColor: AppColor.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              //Header con gradiente
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColor.primary, AppColor.secundary]),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hola, Jugador!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Listo para jugar hoy?', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/100'),radius: 2,),
                      ],
                    ),
                    SizedBox(height:20),
                    //Card para unirse a juego (esto es parte de la epica 5)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          TextField(decoration: InputDecoration(hintText:'Ingresa PIN de juego', border: InputBorder.none)),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/joinLobby'),
                            child: Text('ENTRAR A JUGAR'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColor.accent, minimumSize:Size(double.infinity,50)),
                          ),
                        ],
                      )
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Seccion de Recientes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        Text('Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(onPressed:(){}, child: Text('Ver todo')),
                      ],
                    ),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentKahoots.length,
                        itemBuilder: (context, index)=> Container(
                          width: 140,
                          margin: EdgeInsets.only(right:10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),border: Border(left: BorderSide(color: AppColor.primary,width:4))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recentKahoots[index].title, style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Hace 2 dias - 80% correcto', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    //Seccion Recomendados con grid staggered
                    Text('Recomendado para ti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    staggered.StaggeredGrid.count(
                      crossAxisCount: 2,
                      children: recommendedKahoots.map((kahoot) => KahootCard(kahoot: kahoot, onTap: () => Navigator.pushNamed(context, '/gameDetail'))).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: ()=>Navigator.pushNamed(context,'/create'),
          backgroundColor: AppColor.primary,
          child: Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _builBottonNav(context,0),
      );
  }

  Widget _builBottonNav(BuildContext context, int currentIndex){
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index){
        if(index == 0) Navigator.pushReplacementNamed(context, '/dashboard');
        if(index == 1) Navigator.pushNamed(context, '/discover');
        if(index == 1) Navigator.pushNamed(context, '/library');
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Descubre'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Biblioteca'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
